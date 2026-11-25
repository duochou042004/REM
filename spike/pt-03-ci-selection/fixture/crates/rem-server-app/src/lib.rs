pub fn id() -> &'static str {
    "rem-server-app"
}

#[cfg(test)]
mod tests {
    #[test]
    fn named() {
        assert_eq!(super::id(), "rem-server-app");
    }
}
