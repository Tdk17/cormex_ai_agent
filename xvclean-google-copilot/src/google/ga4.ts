export async function fetchGa4Kpis(input: {
  accessToken: string;
  propertyId: string;
  startDate: string;
  endDate: string;
}): Promise<unknown> {
  const property = input.propertyId.startsWith('properties/')
    ? input.propertyId
    : `properties/${input.propertyId}`;

  const response = await fetch(`https://analyticsdata.googleapis.com/v1beta/${property}:runReport`, {
    method: 'POST',
    headers: {
      authorization: `Bearer ${input.accessToken}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      dateRanges: [{ startDate: input.startDate, endDate: input.endDate }],
      dimensions: [{ name: 'sessionDefaultChannelGroup' }],
      metrics: [
        { name: 'sessions' },
        { name: 'totalUsers' },
        { name: 'conversions' },
        { name: 'totalRevenue' },
      ],
      orderBys: [{ metric: { metricName: 'sessions' }, desc: true }],
      limit: '100',
    }),
  });
  const json = await response.json();
  if (!response.ok) throw new Error(`GA4 Data API error (${response.status}): ${JSON.stringify(json)}`);
  return json;
}
