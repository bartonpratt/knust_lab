/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const { onRequest } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

const admin = require("firebase-admin");
admin.initializeApp();

exports.sendUserStatusNotification = functions.firestore
  .document("users/{userId}")
  .onUpdate((change, context) => {
    const userId = context.params.userId;
    const updatedData = change.after.data();
    const previousData = change.before.data();

    // Check if the status field is updated
    if (updatedData.status !== previousData.status) {
      const status = updatedData.status;

      // Fetch the user's FCM token from Firestore
      return admin
        .firestore()
        .collection("users")
        .doc(userId)
        .get()
        .then((userDoc) => {
          const userToken = userDoc.data().fcmToken;

          if (userToken) {
            // Send the push notification to the user using FCM
            const payload = {
              notification: {
                title: "User Status Update",
                body: `Your status has been updated to: ${status}`,
              },
            };

            return admin.messaging().sendToDevice(userToken, payload);
          } else {
            console.log("User FCM token not found.");
            return null;
          }
        })
        .catch((error) => {
          console.error("Error sending user status notification:", error);
          return null;
        });
    } else {
      // Status field not updated, do nothing
      return null;
    }
  });

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
