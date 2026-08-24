const { z } = require('zod');

exports.localizacaoSchema = z.object({
    latitude: z.number().gte(-90).lte(90),
    longitude: z.number().gte(-180).lte(180)
}).strict();
