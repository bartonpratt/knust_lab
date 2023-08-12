/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendStatusUpdateNotification = functions.firestore
  .document('users/{userId}')
  .onUpdate((change, context) => {
    const newValue = change.after.data();
    const previousValue = change.before.data();

    // Check if the status field was updated
    if (newValue.status !== previousValue.status) {
      const userId = context.params.userId;
      const status = newValue.status;

      // Get the FCM token for the user
      const fcmToken = newValue.fcmToken;

      if (fcmToken) {
        const message = {
          data: {
            title: 'Status Update',
            body: `Your status has been updated to ${status}`,
          },
          token: fcmToken,
        };

        // Send the FCM notification
        return admin.messaging().send(message)
          .then(() => {
            console.log('Notification sent successfully');
          })
          .catch((error) => {
            console.error('Error sending notification:', error);
          });
      }
    }
    return null;
  });


// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
