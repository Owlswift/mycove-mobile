package com.zsolutions.communityhub

import io.flutter.embedding.android.FlutterFragmentActivity

// local_auth's Android BiometricPrompt integration requires a
// FragmentActivity — plain FlutterActivity doesn't support it.
class MainActivity : FlutterFragmentActivity()
