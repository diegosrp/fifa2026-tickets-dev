-- =====================================================
-- Migration: índices para queries frequentes
-- =====================================================
-- O gargalo principal era cold start de iisnode + tempo de query
-- da rota /api/matches que faz JOIN de matches × teams (×2) × stadiums.
-- Sem índices nas FKs, cada JOIN era table-scan.
--
-- Esses índices aceleram drasticamente:
-- - bracket.js: ORDER BY id, GROUP BY stage, JOIN por stadium_id
-- - matches.js: filtro por stage e stadium_id, JOIN por team
-- - stadiums.js: filtro por country (já tinha PK em id)
--
-- Idempotente — usa IF NOT EXISTS antes de cada CREATE INDEX.
-- =====================================================

SET NOCOUNT ON;

-- ============ matches: índices em FKs e filtros frequentes ============
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_matches_stage' AND object_id = OBJECT_ID('dbo.matches'))
  CREATE INDEX IX_matches_stage ON dbo.matches(stage) INCLUDE (group_name, date, time);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_matches_stadium' AND object_id = OBJECT_ID('dbo.matches'))
  CREATE INDEX IX_matches_stadium ON dbo.matches(stadium_id);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_matches_home_team' AND object_id = OBJECT_ID('dbo.matches'))
  CREATE INDEX IX_matches_home_team ON dbo.matches(home_team_id);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_matches_away_team' AND object_id = OBJECT_ID('dbo.matches'))
  CREATE INDEX IX_matches_away_team ON dbo.matches(away_team_id);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_matches_group_name' AND object_id = OBJECT_ID('dbo.matches'))
  CREATE INDEX IX_matches_group_name ON dbo.matches(group_name) WHERE group_name IS NOT NULL;

-- ============ teams: índice em group_name ============
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_teams_group_name' AND object_id = OBJECT_ID('dbo.teams'))
  CREATE INDEX IX_teams_group_name ON dbo.teams(group_name) WHERE group_name IS NOT NULL;

-- ============ stadiums: índice em country ============
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_stadiums_country' AND object_id = OBJECT_ID('dbo.stadiums'))
  CREATE INDEX IX_stadiums_country ON dbo.stadiums(country);

-- ============ ticket_categories: índice em match_id ============
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ticket_categories_match' AND object_id = OBJECT_ID('dbo.ticket_categories'))
  CREATE INDEX IX_ticket_categories_match ON dbo.ticket_categories(match_id);

-- Validação
SELECT i.name AS index_name, t.name AS table_name
FROM sys.indexes i
JOIN sys.tables t ON i.object_id = t.object_id
WHERE i.name LIKE 'IX_%'
ORDER BY t.name, i.name;

PRINT 'Índices criados/verificados — esperado ~8 índices IX_*';
