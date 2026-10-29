extension AttributesOptions {
    public enum DefaultBehavior {
        /// Applies to all custom attributes.
        case always
        /// Applies to custom attributes without arguments only.
        case nameOnly
        /// Applies to no custom attributes.
        case never
    }
}
