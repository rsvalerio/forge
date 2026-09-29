//! rust-ci.yml fixture: one unit test for nextest and one doctest for
//! `ops test-doc`, since nextest does not run doctests.

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
