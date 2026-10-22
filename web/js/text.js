// Fixed text. The caveats are the mandatory sentences of dashboard/README.md §8, verbatim (C-12 source line included).

export const SOURCE_LINE = 'Source: NOCOPO OCDS export (package metadata dated 2021-05-03; releases dated to 2026-07-29), SHA-256 6151466…bc90c.';

export const CAVEATS = {
  footer: 'Figures describe what was published to the Nigeria Open Contracting Portal (NOCOPO OCDS export; package metadata dated 2021-05-03, releases dated to 2026-07-29; SHA-256 6151466…bc90c). They show patterns in reported data, not findings about conduct.',
  supplier: 'Supplier concentration is a lower bound. Suppliers are identified by source ID and are not merged on name similarity.',
  competition: 'Number of tenderers as recorded; the meaning (bids received or expressions of interest) is unconfirmed. A single bidder is a count pattern, not evidence of impropriety. Direct Procurement, Sole Source and Repeat Procurement are single-supplier by design, so compare like with like.',
  budget: 'A budget is a plan, not a contract estimate or spend. A ratio above or below 1 is a difference between two recorded figures, not an overrun or a saving. Budgets under NGN 100,000 look like placeholder entries and are kept; extreme ratios come from them.',
  budgetOver10: 'Awards above 10 times budget are a small group of OCIDs that hold a large share of the award value (see the band chart for the counts). Pattern only; cause not established; units and budget entry should be checked against the source.',
  timing: 'Medians describe only processes with valid dates and are not estimates for all procurement.',
  entity: 'Entities differ in size and method mix. Ranks and medians show relative position, not a target. A KPI is shown only where the entity meets the minimum number of records (10 awards, 30 tenders, 20 contracts, 30 processes). Entities are identified by buyer ID and are not merged.',
  implementation: 'Implementation coverage shows whether implementation data (milestones or transactions) was published. It is a reporting signal, not a measure of contract performance. Transaction dates are absent and transaction values are not analysed (DQ-11, DQ-12).',
  funnel: 'Most processes were published only at planning stage; conversion reflects what the portal holds, not how procurement progressed.',
  dataQuality: 'The portal test entity (DQ-20) is removed before every population is defined, and the bare buyer ID (DQ-19) is excluded from entity views. Issue counts overlap; they are not additive. Materiality ratings are in sql/06_analysis/07.',
};

export const PAGES = [
  { id: 'overview', label: '1 Executive overview', title: 'Executive overview',
    question: 'What the published record shows, and how complete it is. Every figure is shown with the number of records it is based on.' },
  { id: 'suppliers', label: '2a Supplier concentration', title: 'Supplier concentration',
    question: 'How concentrated is awarded value among suppliers with a usable supplier ID?' },
  { id: 'competition', label: '2b Competition', title: 'Competition',
    question: 'How many tenderers do processes record, and where is the single-bidder share higher or lower?' },
  { id: 'budget', label: '3 Budget versus award', title: 'Budget versus award',
    question: 'How does awarded value compare with recorded budgets, and where do entities and methods differ?' },
  { id: 'timing', label: '4 Procurement-cycle timing', title: 'Procurement-cycle timing',
    question: 'What do valid dates say about how long stages take, and where are dates too incomplete to measure?' },
  { id: 'entities', label: '5 Entity benchmark', title: 'Entity benchmark',
    question: 'Which entities account for the most activity, and how do they compare on the KPIs?' },
  { id: 'implementation', label: '6 Implementation and lifecycle', title: 'Implementation and lifecycle',
    question: 'What share of contracts has implementation data published, and how far do processes progress?' },
  { id: 'data-quality', label: '7 Data quality and coverage', title: 'Data quality and coverage',
    question: 'Which data-quality issues could materially affect how the figures are read?' },
];
