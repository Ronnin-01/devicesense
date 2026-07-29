package com.example.devicesense.platform

interface PermissionResultListener {

    fun onRequestPermissionsResult(
            requestCode: Int,
            permissions: Array<String>,
            grantResults: IntArray,
    )
}
