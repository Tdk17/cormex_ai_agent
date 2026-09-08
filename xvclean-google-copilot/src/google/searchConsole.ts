export async function fetchSearchConsoleKpis(input: {
  accessToken: string;
  siteUrl: string;
  startDate: string;
  endDate: string;
}): Promise<unknown> {
  const encodedSite = encodeURIComponent(input.siteUrl);
  const response = await fetch(
    `https://searchconsole.googleapis.com/webmasters/v3/sites/${encodedSite}/searchAnalytics/query`,
    {
      method: 'POST',
      headers: {
        authorization: `Bearer ${input.accessToken}`,
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        startDate: input.startDate,
        endDate: input.endDate,
        dimensions: ['query', 'page'],
        rowLimit: 250,
      }),
    },
  );
  const json = await response.json();
  if (!response.ok) {
    throw new Error(`Search Console API error (${response.status}): ${JSON.stringify(json)}`);
  }
  return json;
}
