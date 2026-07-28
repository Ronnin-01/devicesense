package com.example.devicesense.platform.permissions

/**
 * Represents an Android runtime permission after mapping from Flutter.
 *
 * @property manifestPermission Android Manifest permission string.
 * @property runtimeRequired Whether this permission actually requires a runtime request on the
 * current Android version.
 */
data class PermissionInfo(
        val manifestPermission: String,
        val runtimeRequired: Boolean,
)
