const express = require('express');
const app = express();
const port = 3000; // Change this to your desired port

const admin = require('firebase-admin');
const serviceAccount = require('D:/Joseph -Do not DELETE/Projects/temp/jb/knust_lab/server/knust-lab-firebase-adminsdk-7ekjw-4a8596af3f.json')

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

app.use(express.json());

// Define a route to handle sending FCM notifications
app.post('/send-notification', async (req, res) => {
  const { userId, status, fcmToken } = req.body;

  const message = {
    data: {
      title: 'Status Update',
      body: `Your status has been updated to ${status}`,
    },
    token: fcmToken,
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('Notification sent:', response);
    res.json({ success: true });
  } catch (error) {
    console.error('Error sending notification:', error);
    res.status(500).json({ error: 'Failed to send notification' });
  }
});

app.listen(port, () => {
  console.log(`Server is running on http://localhost:${port}`);
});
