# Job source adapters

Implement each source as a separate `JobSource` adapter and document:
- permitted access method (official API, feed, public page, or user-authorized browser workflow);
- required configuration;
- rate limits and terms review;
- fields extracted and known limitations.

Do not implement CAPTCHA bypass, stealth/fingerprint evasion, session-cookie export, or scraping behind access controls. Start with public company career pages and official feeds/APIs where available.
