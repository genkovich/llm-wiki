# Wiki Index

<!-- If the wiki is not at the vault root — replace 'wiki/' in FROM with the full path (e.g. "Project/wiki/entities") -->

Catalog of the LLM-curated wiki. Details — see [[CLAUDE]].

## Quick links

- [[overview]] — current synthesis of the domain
- [[log]] — chronological ingest/query/lint trace
- [[CLAUDE|Schema & Workflows]]

## Entities

```dataview
TABLE WITHOUT ID
  file.link AS "Entity",
  confidence,
  last_updated AS "Updated",
  length(sources) AS "Sources"
FROM "wiki/entities"
WHERE type = "entity"
SORT last_updated DESC
```

## Concepts

```dataview
TABLE WITHOUT ID
  file.link AS "Concept",
  confidence,
  last_updated AS "Updated"
FROM "wiki/concepts"
WHERE type = "concept"
SORT last_updated DESC
```

## Sources

```dataview
TABLE WITHOUT ID
  file.link AS "Source",
  fetched,
  url
FROM "wiki/sources"
WHERE type = "source"
SORT fetched DESC
```

## Comparisons

```dataview
LIST
FROM "wiki/comparisons"
WHERE type = "comparison"
SORT last_updated DESC
```

## Open Questions

```dataview
LIST
FROM "wiki/questions"
SORT file.ctime DESC
```
