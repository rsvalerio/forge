//! rust-ci.yml fixture: one unit test and one doctest, so `ops qa` runs both
//! its test and doctest steps.

/// The answer.
///
/// ```
/// assert_eq!(forge_fixture_ops::answer(), 42);
/// ```
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
