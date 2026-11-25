-- P0-PT-02 throwaway spike: minimal schema for the sync §3 write path. Not production code.
CREATE TABLE users (id bigint PRIMARY KEY, last_user_seq bigint NOT NULL DEFAULT 0, status text NOT NULL DEFAULT 'active');
CREATE TABLE sessions (id bigint PRIMARY KEY, user_id bigint NOT NULL REFERENCES users, revoked_at timestamptz, reason text);
CREATE TABLE conversations (id bigint PRIMARY KEY, last_seq bigint NOT NULL DEFAULT 0);
CREATE TABLE members (conversation_id bigint REFERENCES conversations, user_id bigint REFERENCES users,
  joined_seq bigint NOT NULL, left_seq bigint, PRIMARY KEY (conversation_id, user_id));
CREATE TABLE messages (conversation_id bigint, seq bigint, message_id uuid NOT NULL UNIQUE, sender_id bigint NOT NULL,
  session_id bigint NOT NULL, body text NOT NULL, created_at timestamptz NOT NULL DEFAULT now(), PRIMARY KEY (conversation_id, seq));
CREATE TABLE events (conversation_id bigint, seq bigint, kind text NOT NULL, payload jsonb NOT NULL, PRIMARY KEY (conversation_id, seq));
CREATE TABLE idempotency (user_id bigint, operation_id uuid, kind text NOT NULL, target bigint NOT NULL, hash bytea NOT NULL,
  result jsonb NOT NULL, created_at timestamptz NOT NULL DEFAULT now(), PRIMARY KEY (user_id, operation_id));
CREATE TABLE outbox (conversation_id bigint, seq bigint, PRIMARY KEY (conversation_id, seq));
CREATE TABLE search_index (conversation_id bigint, seq bigint, doc tsvector NOT NULL, PRIMARY KEY (conversation_id, seq));
CREATE INDEX search_index_doc ON search_index USING gin (doc);
CREATE TABLE user_events (user_id bigint, user_seq bigint, kind text NOT NULL, payload jsonb NOT NULL, PRIMARY KEY (user_id, user_seq));

-- sync §3 steps 1-6 for message.send. p_pause sleeps after the session lock (race drivers only).
CREATE FUNCTION send_message(p_session bigint, p_conv bigint, p_op uuid, p_body text, p_pause float8 DEFAULT 0)
RETURNS jsonb LANGUAGE plpgsql AS $$
DECLARE s sessions; i idempotency; v_seq bigint; v_mid uuid := gen_random_uuid(); v_res jsonb;
        v_hash bytea := sha256(convert_to('message.send|' || p_conv || '|' || p_body, 'UTF8'));
BEGIN
  SELECT * INTO s FROM sessions WHERE id = p_session FOR SHARE;                       -- 1 session
  IF NOT FOUND OR s.revoked_at IS NOT NULL THEN RETURN '{"status":"session_revoked"}'; END IF;
  PERFORM pg_sleep(p_pause);
  PERFORM 1 FROM conversations WHERE id = p_conv FOR UPDATE;                           -- 2 lock
  SELECT * INTO i FROM idempotency WHERE user_id = s.user_id AND operation_id = p_op;  -- 3 idempotency
  IF FOUND THEN
    IF i.kind = 'message.send' AND i.target = p_conv AND i.hash = v_hash THEN
      RETURN i.result || '{"status":"duplicate"}';
    END IF;
    RETURN '{"status":"operation_conflict"}';
  END IF;
  PERFORM 1 FROM members WHERE conversation_id = p_conv AND user_id = s.user_id AND left_seq IS NULL;  -- 4 right
  IF NOT FOUND THEN RETURN '{"status":"forbidden"}'; END IF;
  UPDATE conversations SET last_seq = last_seq + 1 WHERE id = p_conv RETURNING last_seq INTO v_seq;   -- 5 write
  v_res := jsonb_build_object('operation_id', p_op, 'message_id', v_mid, 'conversation_id', p_conv, 'seq', v_seq,
                              'server_time', clock_timestamp());
  INSERT INTO messages VALUES (p_conv, v_seq, v_mid, s.user_id, p_session, p_body);
  INSERT INTO events VALUES (p_conv, v_seq, 'message.created', jsonb_build_object('message_id', v_mid, 'sender_id', s.user_id));
  INSERT INTO idempotency VALUES (s.user_id, p_op, 'message.send', p_conv, v_hash, v_res);
  INSERT INTO outbox VALUES (p_conv, v_seq);
  INSERT INTO search_index VALUES (p_conv, v_seq, to_tsvector('simple', p_body));
  RETURN v_res || '{"status":"ok"}';                                                   -- 6 commit (caller)
END $$;

-- Membership removal: session, conversation lock, then the affected user row (§3.1 order).
CREATE FUNCTION remove_member(p_actor_session bigint, p_conv bigint, p_user bigint) RETURNS jsonb LANGUAGE plpgsql AS $$
DECLARE s sessions; r bigint; us bigint;
BEGIN
  SELECT * INTO s FROM sessions WHERE id = p_actor_session FOR SHARE;
  IF NOT FOUND OR s.revoked_at IS NOT NULL THEN RETURN '{"status":"session_revoked"}'; END IF;
  PERFORM 1 FROM conversations WHERE id = p_conv FOR UPDATE;
  PERFORM 1 FROM users WHERE id = p_user FOR UPDATE;
  UPDATE conversations SET last_seq = last_seq + 1 WHERE id = p_conv RETURNING last_seq INTO r;
  UPDATE members SET left_seq = r WHERE conversation_id = p_conv AND user_id = p_user AND left_seq IS NULL;
  INSERT INTO events VALUES (p_conv, r, 'member.removed', jsonb_build_object('user_id', p_user));
  INSERT INTO outbox VALUES (p_conv, r);
  UPDATE users SET last_user_seq = last_user_seq + 1 WHERE id = p_user RETURNING last_user_seq INTO us;
  INSERT INTO user_events VALUES (p_user, us, 'user.membership_changed', jsonb_build_object('conversation_id', p_conv));
  RETURN jsonb_build_object('status', 'ok', 'seq', r);
END $$;

-- Session revocation. p_ordered: lock the two session rows in ascending id (§3.1); false = actor first (control).
CREATE FUNCTION revoke_session(p_actor bigint, p_target bigint, p_pause float8 DEFAULT 0, p_ordered boolean DEFAULT true)
RETURNS jsonb LANGUAGE plpgsql AS $$
DECLARE first_id bigint; second_id bigint; a sessions;
BEGIN
  IF p_ordered THEN first_id := least(p_actor, p_target); second_id := greatest(p_actor, p_target);
  ELSE first_id := p_actor; second_id := p_target; END IF;
  IF first_id = p_target THEN PERFORM 1 FROM sessions WHERE id = first_id FOR UPDATE;
  ELSE PERFORM 1 FROM sessions WHERE id = first_id FOR SHARE; END IF;
  PERFORM pg_sleep(p_pause);
  IF second_id <> first_id THEN
    IF second_id = p_target THEN PERFORM 1 FROM sessions WHERE id = second_id FOR UPDATE;
    ELSE PERFORM 1 FROM sessions WHERE id = second_id FOR SHARE; END IF;
  END IF;
  SELECT * INTO a FROM sessions WHERE id = p_actor;              -- re-validate under the locks
  IF a.revoked_at IS NOT NULL THEN RETURN '{"status":"session_revoked"}'; END IF;
  UPDATE sessions SET revoked_at = clock_timestamp(), reason = 'admin' WHERE id = p_target AND revoked_at IS NULL;
  RETURN '{"status":"ok"}';
END $$;

-- Group creation with p_n members: the conversation, then every member's user row ascending (§3.1),
-- one user event per member.
CREATE FUNCTION create_group(p_conv bigint, p_first_user bigint, p_n int) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO conversations VALUES (p_conv, 1);
  PERFORM 1 FROM conversations WHERE id = p_conv FOR UPDATE;
  PERFORM 1 FROM users WHERE id BETWEEN p_first_user AND p_first_user + p_n - 1 ORDER BY id FOR UPDATE;
  INSERT INTO members SELECT p_conv, id, 1, NULL FROM users WHERE id BETWEEN p_first_user AND p_first_user + p_n - 1;
  INSERT INTO events VALUES (p_conv, 1, 'group.created', jsonb_build_object('members', p_n));
  INSERT INTO outbox VALUES (p_conv, 1);
  WITH u AS (UPDATE users SET last_user_seq = last_user_seq + 1
             WHERE id BETWEEN p_first_user AND p_first_user + p_n - 1 RETURNING id, last_user_seq)
  INSERT INTO user_events SELECT id, last_user_seq, 'user.membership_changed', jsonb_build_object('conversation_id', p_conv) FROM u;
END $$;

-- Dissolve: one membership change for every member (conversation lock, then all user rows ascending).
CREATE FUNCTION dissolve_group(p_conv bigint) RETURNS void LANGUAGE plpgsql AS $$
DECLARE r bigint;
BEGIN
  PERFORM 1 FROM conversations WHERE id = p_conv FOR UPDATE;
  PERFORM 1 FROM users u JOIN members m ON m.user_id = u.id AND m.conversation_id = p_conv AND m.left_seq IS NULL
    ORDER BY u.id FOR UPDATE OF u;
  UPDATE conversations SET last_seq = last_seq + 1 WHERE id = p_conv RETURNING last_seq INTO r;
  INSERT INTO events VALUES (p_conv, r, 'group.dissolved', '{}');
  INSERT INTO outbox VALUES (p_conv, r);
  WITH m AS (UPDATE members SET left_seq = r WHERE conversation_id = p_conv AND left_seq IS NULL RETURNING user_id),
       u AS (UPDATE users SET last_user_seq = last_user_seq + 1 WHERE id IN (SELECT user_id FROM m) RETURNING id, last_user_seq)
  INSERT INTO user_events SELECT id, last_user_seq, 'user.membership_changed', jsonb_build_object('conversation_id', p_conv) FROM u;
END $$;

-- Seed: 50,064 users with one session each (session id = user id); conversations 1-5 (scenarios)
-- and 101-164 (spread load), each with members 1-64.
INSERT INTO users (id) SELECT generate_series(1, 50064);
INSERT INTO sessions (id, user_id) SELECT id, id FROM users;
INSERT INTO conversations (id) SELECT unnest(ARRAY[1,2,3,4,5]) UNION ALL SELECT generate_series(101, 164);
INSERT INTO members SELECT c.id, u, 0, NULL FROM conversations c, generate_series(1, 64) u;
ANALYZE;
