// Vercel Serverless Function: /api/chase-reminder
// Sends a zero-login magic-link reminder via Resend (Free tier: 3,000 emails/mo)
export default async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });
  const { clientEmail, clientName, firmName, magicUrl, missingItems } = req.body || {};
  if (!clientEmail || !magicUrl || !Array.isArray(missingItems)) {
    return res.status(400).json({ error: 'Missing required fields' });
  }

  const listHtml = missingItems.map(i => `<li>${i}</li>`).join('');
  const resp = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${process.env.RESEND_API_KEY}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      from: `${firmName || 'DocReady'} <reminders@yourdomain.com>`,
      to: [clientEmail],
      subject: `Quick upload needed for your monthly close (${missingItems.length} item${missingItems.length === 1 ? '' : 's'})`,
      html: `<p>Hi ${clientName},</p><p>To keep your books on schedule, please upload these remaining items (no login or password required):</p><ul>${listHtml}</ul><p><a href="${magicUrl}" style="display:inline-block;padding:12px 20px;background:#1D4ED8;color:#fff;text-decoration:none;border-radius:8px;font-weight:600;">Upload Files in 30 Seconds</a></p>`
    })
  });

  if (!resp.ok) return res.status(502).json({ error: 'Email provider error' });
  return res.status(200).json({ ok: true });
}
