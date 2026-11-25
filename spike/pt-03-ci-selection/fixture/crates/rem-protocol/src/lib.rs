pub fn id() -> &'static str {
    "rem-protocol"
}

#[cfg(test)]
mod tests {
    #[test]
    fn named() {
        assert_eq!(super::id(), "rem-protocol");
    }
}
