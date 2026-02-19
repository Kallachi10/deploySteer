import 'dart:math';

class Quaternion {
  double w, x, y, z;

  Quaternion(this.w, this.x, this.y, this.z);

  Quaternion copy() => Quaternion(w, x, y, z);

  Quaternion normalize() {
    double norm = sqrt(w * w + x * x + y * y + z * z);
    return Quaternion(w / norm, x / norm, y / norm, z / norm);
  }

  Quaternion multiply(Quaternion q) {
    return Quaternion(
      w * q.w - x * q.x - y * q.y - z * q.z,
      w * q.x + x * q.w + y * q.z - z * q.y,
      w * q.y - x * q.z + y * q.w + z * q.x,
      w * q.z + x * q.y - y * q.x + z * q.w,
    );
  }

  Quaternion conjugate() => Quaternion(w, -x, -y, -z);

  // Convert to Euler angles (yaw, pitch, roll) in radians
  List<double> toEuler() {
    double yaw = atan2(2 * (w * z + x * y), 1 - 2 * (y * y + z * z));
    double pitch = asin(2 * (w * y - z * x));
    double roll = atan2(2 * (w * x + y * z), 1 - 2 * (x * x + y * y));
    return [yaw, pitch, roll];
  }
}

class MadgwickAHRS {
  Quaternion q = Quaternion(1, 0, 0, 0); // Initial quaternion
  double beta = 0.1; // Algorithm gain
  double sampleFreq = 100.0; // Sample frequency

  void update(double gx, double gy, double gz, double ax, double ay, double az, double mx, double my, double mz) {
    double recipNorm;
    double s0, s1, s2, s3;
    double qDot1, qDot2, qDot3, qDot4;
    double hx, hy;
    double _2q0mx, _2q0my, _2q0mz, _2q1mx, _2bx, _2bz, _4bx, _4bz, _2q0, _2q1, _2q2, _2q3, _2q0q2, _2q2q3, q0q0, q0q1, q0q2, q0q3, q1q1, q1q2, q1q3, q2q2, q2q3, q3q3;

    // Rate of change of quaternion from gyroscope
    qDot1 = 0.5 * (-q.x * gx - q.y * gy - q.z * gz);
    qDot2 = 0.5 * (q.w * gx + q.y * gz - q.z * gy);
    qDot3 = 0.5 * (q.w * gy - q.x * gz + q.z * gx);
    qDot4 = 0.5 * (q.w * gz + q.x * gy - q.y * gx);

    // Compute feedback only if accelerometer measurement valid (avoids NaN in accelerometer normalisation)
    if (!((ax == 0.0) && (ay == 0.0) && (az == 0.0))) {
      // Normalise accelerometer measurement
      recipNorm = 1.0 / sqrt(ax * ax + ay * ay + az * az);
      ax *= recipNorm;
      ay *= recipNorm;
      az *= recipNorm;

      // Normalise magnetometer measurement
      recipNorm = 1.0 / sqrt(mx * mx + my * my + mz * mz);
      mx *= recipNorm;
      my *= recipNorm;
      mz *= recipNorm;

      // Auxiliary variables to avoid repeated arithmetic
      _2q0mx = 2.0 * q.w * mx;
      _2q0my = 2.0 * q.w * my;
      _2q0mz = 2.0 * q.w * mz;
      _2q1mx = 2.0 * q.x * mx;
      _2q0 = 2.0 * q.w;
      _2q1 = 2.0 * q.x;
      _2q2 = 2.0 * q.y;
      _2q3 = 2.0 * q.z;
      _2q0q2 = 2.0 * q.w * q.y;
      _2q2q3 = 2.0 * q.y * q.z;
      q0q0 = q.w * q.w;
      q0q1 = q.w * q.x;
      q0q2 = q.w * q.y;
      q0q3 = q.w * q.z;
      q1q1 = q.x * q.x;
      q1q2 = q.x * q.y;
      q1q3 = q.x * q.z;
      q2q2 = q.y * q.y;
      q2q3 = q.y * q.z;
      q3q3 = q.z * q.z;

      // Reference direction of Earth's magnetic field
      hx = mx * q0q0 - _2q0my * q.z + _2q0mz * q.y + mx * q1q1 + _2q1 * my * q.y + _2q1 * mz * q.z - mx * q2q2 - mx * q3q3;
      hy = _2q0mx * q.z + my * q0q0 - _2q0mz * q.x + _2q1mx * q.y - my * q1q1 + my * q2q2 + _2q2 * mz * q.z - my * q3q3;
      _2bx = sqrt(hx * hx + hy * hy);
      _2bz = -_2q0mx * q.y + _2q0my * q.x + mz * q0q0 + _2q1mx * q.z - mz * q1q1 + _2q2 * my * q.z - mz * q2q2 + mz * q3q3;
      _4bx = 2.0 * _2bx;
      _4bz = 2.0 * _2bz;

      // Gradient decent algorithm corrective step
      s0 = -_2q2 * (2.0 * q1q3 - _2q0q2 - ax) + _2q1 * (2.0 * q0q1 + _2q2q3 - ay) - _2bz * q.y * (_2bx * (0.5 - q2q2 - q3q3) + _2bz * (q1q3 - q0q2) - mx) + (-_2bx * q.z + _2bz * q.x) * (_2bx * (q1q2 - q0q3) + _2bz * (q0q1 + q2q3) - my) + _2bx * q.y * (_2bx * (q0q2 + q1q3) + _2bz * (0.5 - q1q1 - q2q2) - mz);
      s1 = _2q3 * (2.0 * q1q3 - _2q0q2 - ax) + _2q0 * (2.0 * q0q1 + _2q2q3 - ay) - 4.0 * q.x * (1 - 2.0 * q1q1 - 2.0 * q2q2 - az) + _2bz * q.z * (_2bx * (0.5 - q2q2 - q3q3) + _2bz * (q1q3 - q0q2) - mx) + (_2bx * q.w + _2bz * q.y) * (_2bx * (q1q2 - q0q3) + _2bz * (q0q1 + q2q3) - my) + (_2bx * q.z - _4bz * q.x) * (_2bx * (q0q2 + q1q3) + _2bz * (0.5 - q1q1 - q2q2) - mz);
      s2 = -_2q0 * (2.0 * q1q3 - _2q0q2 - ax) + _2q3 * (2.0 * q0q1 + _2q2q3 - ay) - 4.0 * q.y * (1 - 2.0 * q1q1 - 2.0 * q2q2 - az) + (-_4bx * q.y - _2bz * q.w) * (_2bx * (0.5 - q2q2 - q3q3) + _2bz * (q1q3 - q0q2) - mx) + (_2bx * q.x + _2bz * q.z) * (_2bx * (q1q2 - q0q3) + _2bz * (q0q1 + q2q3) - my) + (_2bx * q.w - _4bz * q.y) * (_2bx * (q0q2 + q1q3) + _2bz * (0.5 - q1q1 - q2q2) - mz);
      s3 = _2q1 * (2.0 * q1q3 - _2q0q2 - ax) + _2q2 * (2.0 * q0q1 + _2q2q3 - ay) + (-_4bx * q.z + _2bz * q.w) * (_2bx * (0.5 - q2q2 - q3q3) + _2bz * (q1q3 - q0q2) - mx) + (-_2bx * q.w + _2bz * q.x) * (_2bx * (q1q2 - q0q3) + _2bz * (q0q1 + q2q3) - my) + _2bx * q.x * (_2bx * (q0q2 + q1q3) + _2bz * (0.5 - q1q1 - q2q2) - mz);

      // Normalise step magnitude
      recipNorm = 1.0 / sqrt(s0 * s0 + s1 * s1 + s2 * s2 + s3 * s3);
      s0 *= recipNorm;
      s1 *= recipNorm;
      s2 *= recipNorm;
      s3 *= recipNorm;

      // Apply feedback step
      qDot1 -= beta * s0;
      qDot2 -= beta * s1;
      qDot3 -= beta * s2;
      qDot4 -= beta * s3;
    }

    // Integrate rate of change of quaternion to yield quaternion
    q.w += qDot1 * (1.0 / sampleFreq);
    q.x += qDot2 * (1.0 / sampleFreq);
    q.y += qDot3 * (1.0 / sampleFreq);
    q.z += qDot4 * (1.0 / sampleFreq);

    // Normalise quaternion
    q = q.normalize();
  }

  List<double> getEuler() => q.toEuler();
}