import { reader } from './lectura.js';

export const { options, setup, handleSummary, teardown, run } = reader('PERF-03');
export default run;
