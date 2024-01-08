// Generated file.
//
// If you wish to remove Flutter's multidex support, delete this entire file.
//
// Modifications to this file should be done in a copy under a different name
// as this file may be regenerated.

package io.flutter.app;

import android.app.Application;
import android.content.Context;
import androidx.annotation.CallSuper;
import androidx.multidex.MultiDex;

//import com.google.firebase.FirebaseApp;
//import com.google.firebase.appcheck.FirebaseAppCheck;
//import com.google.firebase.appcheck.playintegrity.PlayIntegrityAppCheckProviderFactory;


/**
 * Extension of {@link android.app.Application}, adding multidex support.
 */
public class FlutterMultiDexApplication extends Application {
  @Override
  @CallSuper
  protected void attachBaseContext(Context base) {
    super.attachBaseContext(base);
    MultiDex.install(this);
  }

  // @Override
  // public void onCreate(){
  //   super.onCreate();
  //   //Initialize Firebase
  //   FirebaseApp.initializeApp(this);

  //   //Initialize Firebase App Check
  //   FirebaseAppCheck firebaseAppCheck = FirebaseAppCheck.getInstance();
  //   firebaseAppCheck.installAppCheckProviderFactory(
  //     PlayIntegrityAppCheckProviderFactory.getInstance()
  //   );
    
  //}
}
