pub fn id() -> &'static str {
    "rem-client-wasm"
}

#[cfg(test)]
mod tests {
    #[test]
    fn named() {
        assert_eq!(super::id(), "rem-client-wasm");
    }
}
