#!/usr/bin/env python3
"""Ensemble-cast network for one actor's movies, from the recommendations
dataset: nodes are actors, an edge between two actors means they appeared
in the same movie together (edge weight = how many movies), the center
actor highlighted. Run ./load.sh first to produce recommendations.db.

    pip install marsdb networkx matplotlib
    python3 actor_network.py --center "Robert De Niro" --movies 8
"""

import argparse
import sys

import marsdb
import networkx as nx
import matplotlib.pyplot as plt


def cypher_string_literal(s: str) -> str:
    """marsdb's Python binding has no $param support yet (only
    `execute(cypher)`, no `execute_with_params` -- unlike the Rust API
    it wraps), so a value from outside the query text has to be inlined
    as a literal. Escapes the same backslash-escape set MarsDB's lexer
    accepts (see CYPHER_COVERAGE.md) -- not a general-purpose sanitizer,
    fine for a value you typed on your own command line, not for
    untrusted input."""
    escaped = s.replace("\\", "\\\\").replace("'", "\\'")
    return f"'{escaped}'"


def build_graph(db: marsdb.Database, center: str, movie_limit: int) -> nx.Graph:
    rows = db.execute(
        f"MATCH (center:Person {{name: {cypher_string_literal(center)}}})-[:ACTED_IN]->(m:Movie) "
        f"WITH m LIMIT {int(movie_limit)} "
        f"MATCH (m)<-[:ACTED_IN]-(actor:Person) "
        f"RETURN m.title AS movie, collect(actor.name) AS cast"
    )
    if not rows:
        sys.exit(f"No movies found for {center!r} -- check the name matches exactly.")

    g = nx.Graph()
    for row in rows:
        cast = row["cast"]
        for actor in cast:
            g.add_node(actor)
        for i, a in enumerate(cast):
            for b in cast[i + 1 :]:
                if g.has_edge(a, b):
                    g[a][b]["weight"] += 1
                    g[a][b]["movies"].append(row["movie"])
                else:
                    g.add_edge(a, b, weight=1, movies=[row["movie"]])
    return g


def draw(g: nx.Graph, center: str, out_path: str) -> None:
    pos = nx.spring_layout(g, seed=7, k=0.6)
    node_colors = ["#d62728" if n == center else "#1f77b4" for n in g.nodes]
    node_sizes = [900 if n == center else 300 + 80 * g.degree(n) for n in g.nodes]
    edge_widths = [g[u][v]["weight"] * 1.5 for u, v in g.edges]

    plt.figure(figsize=(13, 10))
    nx.draw_networkx_edges(g, pos, width=edge_widths, alpha=0.4, edge_color="#888888")
    nx.draw_networkx_nodes(g, pos, node_color=node_colors, node_size=node_sizes)
    nx.draw_networkx_labels(g, pos, font_size=8)
    plt.title(f"{center}'s co-star network (edge width = shared movies)")
    plt.axis("off")
    plt.tight_layout()
    plt.savefig(out_path, dpi=150)
    print(f"Wrote {out_path} ({g.number_of_nodes()} actors, {g.number_of_edges()} co-star pairs)")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--db", default="recommendations.db")
    parser.add_argument("--center", default="Robert De Niro")
    parser.add_argument("--movies", type=int, default=8, help="how many of the center actor's movies to pull the ensemble cast from")
    parser.add_argument("--out", default="actor_network.png")
    args = parser.parse_args()

    db = marsdb.Database.open(args.db)
    g = build_graph(db, args.center, args.movies)
    draw(g, args.center, args.out)


if __name__ == "__main__":
    main()
