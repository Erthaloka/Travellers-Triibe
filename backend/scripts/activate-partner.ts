import mongoose from 'mongoose';
import dotenv from 'dotenv';

dotenv.config();

async function activatePartner() {
  try {
    await mongoose.connect(process.env.MONGODB_URI!);
    console.log('Connected to MongoDB');

    const result = await mongoose.connection.db.collection('partners').updateOne(
      { _id: new mongoose.Types.ObjectId('6952b07ac09177bde30f24cd') },
      { $set: { status: 'ACTIVE', isVerified: true } }
    );

    console.log('Updated:', result.modifiedCount);
    await mongoose.disconnect();
    console.log('Disconnected');
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

activatePartner();
