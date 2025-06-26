// Firebase Cloud Function untuk Monitoring Location Tracking
// Deploy: firebase deploy --only functions

const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Monitor location tracking status dan detect bugs
 * Triggered setiap kali data di /locations/{userId} berubah
 */
exports.monitorLocationTracking = functions.database
  .ref('/locations/{userId}')
  .onUpdate(async (change, context) => {
    const userId = context.params.userId;
    const newData = change.after.val();
    const oldData = change.before.val();

    try {
      await checkLocationTrackingHealth(userId, newData, oldData);
    } catch (error) {
      console.error('Error monitoring location tracking:', error);
    }
  });

/**
 * Monitor saat user pertama kali start tracking
 */
exports.onLocationTrackingStart = functions.database
  .ref('/locations/{userId}')
  .onCreate(async (snapshot, context) => {
    const userId = context.params.userId;
    const data = snapshot.val();

    console.log(`User ${userId} started location tracking`);
    
    // Optional: Send notification to travel admin
    // await notifyTravelAdmin(userId, 'TRACKING_STARTED', data);
  });

/**
 * Check kesehatan location tracking
 */
async function checkLocationTrackingHealth(userId, newData, oldData) {
  const currentTime = Date.now();
  const lastUpdate = newData.timestamp;
  const timeDiff = currentTime - lastUpdate;
  const maxStaleTime = 15 * 60 * 1000; // 15 menit

  // Scenario 1: Tracking ON tapi koordinat stuck (BUG!)
  if (newData.isTracking && timeDiff > maxStaleTime) {
    await sendBugAlert(userId, {
      type: 'LOCATION_TRACKING_STUCK',
      severity: 'HIGH',
      message: 'Location tracking is ON but coordinates not updating',
      lastUpdate: new Date(lastUpdate).toISOString(),
      staleDuration: Math.floor(timeDiff / 60000) + ' minutes',
      currentCoordinates: {
        lat: newData.latitude,
        lng: newData.longitude
      }
    });
    return;
  }

  // Scenario 2: Tracking berubah dari ON ke OFF (User action)
  if (oldData.isTracking && !newData.isTracking) {
    console.log(`User ${userId} stopped location tracking voluntarily`);
    
    // Optional: Notify travel admin
    await notifyTravelAdmin(userId, 'TRACKING_STOPPED', {
      reason: 'USER_ACTION',
      lastCoordinates: {
        lat: newData.latitude,
        lng: newData.longitude
      }
    });
    return;
  }

  // Scenario 3: Tracking berubah dari OFF ke ON (User action)
  if (!oldData.isTracking && newData.isTracking) {
    console.log(`User ${userId} started location tracking`);
    
    await notifyTravelAdmin(userId, 'TRACKING_STARTED', {
      coordinates: {
        lat: newData.latitude,
        lng: newData.longitude
      }
    });
    return;
  }

  // Scenario 4: Normal operation (tracking ON + fresh coordinates)
  if (newData.isTracking && timeDiff <= maxStaleTime) {
    // All good, no action needed
    return;
  }
}

/**
 * Send bug alert ke travel admin
 */
async function sendBugAlert(userId, alertData) {
  try {
    // Get user data untuk find travel ID
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(userId)
      .get();

    if (!userDoc.exists) {
      console.error(`User ${userId} not found in Firestore`);
      return;
    }

    const userData = userDoc.data();
    const travelId = userData.travelId;
    const userName = userData.name || 'Unknown User';

    if (!travelId) {
      console.error(`User ${userId} has no travelId`);
      return;
    }

    // Get travel admin untuk kirim notification
    const travelAdminQuery = await admin.firestore()
      .collection('users')
      .where('userType', '==', 'travel')
      .where('travelId', '==', travelId)
      .limit(1)
      .get();

    if (travelAdminQuery.empty) {
      console.error(`No travel admin found for travelId: ${travelId}`);
      return;
    }

    const travelAdminDoc = travelAdminQuery.docs[0];
    const travelAdminData = travelAdminDoc.data();

    // Log bug alert
    console.error('🚨 BUG ALERT:', {
      userId,
      userName,
      travelId,
      alertData
    });

    // Save alert to Firestore for admin dashboard
    await admin.firestore()
      .collection('bug_alerts')
      .add({
        userId,
        userName,
        travelId,
        travelAdminId: travelAdminDoc.id,
        alertType: alertData.type,
        severity: alertData.severity,
        message: alertData.message,
        details: alertData,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        resolved: false
      });

    // Send FCM notification to travel admin (if FCM token available)
    if (travelAdminData.fcmToken) {
      const message = {
        token: travelAdminData.fcmToken,
        notification: {
          title: '🚨 Location Tracking Bug Detected',
          body: `${userName}: ${alertData.message}`
        },
        data: {
          type: 'BUG_ALERT',
          userId: userId,
          alertType: alertData.type,
          severity: alertData.severity
        }
      };

      await admin.messaging().send(message);
      console.log('Bug alert notification sent to travel admin');
    }

    // Optional: Send email notification
    // await sendEmailAlert(travelAdminData.email, userName, alertData);

  } catch (error) {
    console.error('Error sending bug alert:', error);
  }
}

/**
 * Notify travel admin tentang location events
 */
async function notifyTravelAdmin(userId, eventType, eventData) {
  try {
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(userId)
      .get();

    if (!userDoc.exists) return;

    const userData = userDoc.data();
    const travelId = userData.travelId;
    const userName = userData.name || 'Unknown User';

    if (!travelId) return;

    // Log event
    console.log(`Location Event - ${eventType}:`, {
      userId,
      userName,
      travelId,
      eventData
    });

    // Save event to Firestore
    await admin.firestore()
      .collection('location_events')
      .add({
        userId,
        userName,
        travelId,
        eventType,
        eventData,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });

  } catch (error) {
    console.error('Error notifying travel admin:', error);
  }
}

/**
 * Periodic check untuk detect stale tracking (run setiap 15 menit)
 */
exports.periodicLocationHealthCheck = functions.pubsub
  .schedule('every 15 minutes')
  .onRun(async (context) => {
    console.log('Running periodic location health check...');

    try {
      const snapshot = await admin.database().ref('locations').once('value');
      const locations = snapshot.val();

      if (!locations) {
        console.log('No location data found');
        return;
      }

      const currentTime = Date.now();
      const maxStaleTime = 15 * 60 * 1000; // 15 menit

      for (const [userId, locationData] of Object.entries(locations)) {
        if (locationData.isTracking) {
          const timeDiff = currentTime - locationData.timestamp;
          
          if (timeDiff > maxStaleTime) {
            console.log(`Found stale tracking for user ${userId}, alerting...`);
            
            await sendBugAlert(userId, {
              type: 'LOCATION_TRACKING_STUCK_PERIODIC',
              severity: 'HIGH',
              message: 'Periodic check: Location tracking stuck detected',
              lastUpdate: new Date(locationData.timestamp).toISOString(),
              staleDuration: Math.floor(timeDiff / 60000) + ' minutes',
              currentCoordinates: {
                lat: locationData.latitude,
                lng: locationData.longitude
              }
            });
          }
        }
      }

      console.log('Periodic location health check completed');
    } catch (error) {
      console.error('Error in periodic location health check:', error);
    }
  });

/**
 * Clean up old location events (run every day)
 */
exports.cleanupOldLocationEvents = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    console.log('Cleaning up old location events...');

    try {
      const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
      
      // Delete old bug alerts
      const oldBugAlerts = await admin.firestore()
        .collection('bug_alerts')
        .where('createdAt', '<', thirtyDaysAgo)
        .get();

      const bugAlertDeletePromises = oldBugAlerts.docs.map(doc => doc.ref.delete());
      await Promise.all(bugAlertDeletePromises);

      // Delete old location events
      const oldLocationEvents = await admin.firestore()
        .collection('location_events')
        .where('createdAt', '<', thirtyDaysAgo)
        .get();

      const locationEventDeletePromises = oldLocationEvents.docs.map(doc => doc.ref.delete());
      await Promise.all(locationEventDeletePromises);

      console.log(`Cleaned up ${oldBugAlerts.size} old bug alerts and ${oldLocationEvents.size} old location events`);
    } catch (error) {
      console.error('Error cleaning up old events:', error);
    }
  });
