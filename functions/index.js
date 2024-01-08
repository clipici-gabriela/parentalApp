const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.createChildAccount = functions.https.onCall((data, context) => {
  // Check if request is made by an authenticated user
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Invalid user.");
  }

  const email = data.email;
  const password = data.password;
  return admin.auth().createUser({
    email: email,
    password: password,
  })
      .then((userRecord) => {
        return {uid: userRecord.uid};
      })
      .catch((error) =>{
        throw new functions.https.HttpsError("unknown", error.message, error);
      });
});
