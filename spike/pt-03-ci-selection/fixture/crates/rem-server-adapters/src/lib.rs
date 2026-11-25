pub fn id() -> &'static str {
    "rem-server-adapters"
}

#[cfg(test)]
mod tests {
    #[test]
    fn named() {
        assert_eq!(super::id(), "rem-server-adapters");
    }
}
