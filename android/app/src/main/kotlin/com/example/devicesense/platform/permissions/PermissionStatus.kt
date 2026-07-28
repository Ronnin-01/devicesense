package com.example.devicesense.platform.permissions

/**
 * Represents the current permission state.
 *
 * The enum names intentionally match Flutter's PermissionStatus.
 */
enum class PermissionStatus {
    GRANTED,
    DENIED,
    PERMANENTLY_DENIED,
    NOT_REQUIRED,
    RESTRICTED,
    LIMITED;

    /** Returns the lowercase enum name expected by Flutter. */
    fun serialize(): String {

        return when (this) {
            GRANTED -> "granted"
            DENIED -> "denied"
            PERMANENTLY_DENIED -> "permanentlyDenied"
            NOT_REQUIRED -> "notRequired"
            RESTRICTED -> "restricted"
            LIMITED -> "limited"
        }
    }
}
