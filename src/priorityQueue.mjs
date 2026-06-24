/**
 * Order the triage queue without ever allowing a normal case to overtake an
 * emergency case. A normal case waiting at least 60 minutes receives an
 * escalation boost so it is considered ahead of newly-arrived normal cases.
 * Earlier arrival wins an otherwise equal score.
 */
export function orderPatients(patients, now = new Date()) {
  if (!Array.isArray(patients)) throw new TypeError('patients must be an array');
  const nowMs = new Date(now).getTime();
  if (Number.isNaN(nowMs)) throw new TypeError('now must be a valid date');

  return patients
    .map((patient) => {
      if (!['EMERGENCY', 'NORMAL'].includes(patient.triage)) {
        throw new RangeError('triage must be EMERGENCY or NORMAL');
      }
      if (!Number.isInteger(patient.severity) || patient.severity < 1 || patient.severity > 10) {
        throw new RangeError('severity must be an integer from 1 to 10');
      }
      const arrivedMs = new Date(patient.arrivedAt).getTime();
      if (Number.isNaN(arrivedMs)) throw new TypeError('arrivedAt must be a valid date');
      const waitedMinutes = Math.max(0, Math.floor((nowMs - arrivedMs) / 60_000));
      return {
        ...patient,
        priority: patient.severity + (patient.triage === 'NORMAL' && waitedMinutes >= 60 ? 10 : 0),
        arrivedMs,
      };
    })
    .sort((a, b) => {
      const triageDifference = Number(b.triage === 'EMERGENCY') - Number(a.triage === 'EMERGENCY');
      if (triageDifference !== 0) return triageDifference;
      if (a.priority !== b.priority) return b.priority - a.priority;
      return a.arrivedMs - b.arrivedMs;
    })
    .map(({ arrivedMs, ...patient }) => patient);
}
