//! rust-ci.yml fixture with exactly one deliberate warning.

pub fn answer() -> u32 {
    // Deliberate `unused_variables` warning: this crate exists to carry one. Do not fix.
    let unused = 41;
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
