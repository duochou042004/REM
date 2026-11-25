pub mod outbox;
pub fn id() -> &'static str {
    "rem-client-core"
}

#[cfg(test)]
mod tests {
    #[test]
    fn named() {
        assert_eq!(super::id(), "rem-client-core");
    }
}
