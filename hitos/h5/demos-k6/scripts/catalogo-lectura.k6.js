import { reader } from './lectura.js';

export const { options, setup, handleSummary, teardown, run } = reader('PERF-01');
export default run;
