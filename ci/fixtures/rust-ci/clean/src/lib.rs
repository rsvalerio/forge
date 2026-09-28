//! rust-ci.yml fixture with no warnings at all.

pub fn answer() -> u32 {
    42
}

#[cfg(test)]
mod tests {
    use super::answer;

    #[test]
    fn answers() {
        assert_eq!(answer(), 42);
    }
}
