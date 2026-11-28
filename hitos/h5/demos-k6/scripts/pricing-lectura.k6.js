import { reader } from './lectura.js';

export const { options, setup, handleSummary, teardown, run } = reader('PERF-02');
export default run;
