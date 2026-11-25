pub fn id() -> &'static str {
    "rem-domain"
}

#[cfg(test)]
mod tests {
    #[test]
    fn named() {
        assert_eq!(super::id(), "rem-domain");
    }
}
