from typing import Any, Dict, List

import requests
from fastapi import FastAPI, HTTPException, Query

app = FastAPI(
    title="BookVault API",
    description="A containerized Book Catalog API that integrates with Google Books.",
    version="0.1.0",
)

GOOGLE_BOOKS_BASE_URL = "https://www.googleapis.com/books/v1/volumes"


def simplify_book_data(item: Dict[str, Any]) -> Dict[str, Any]:
    """
    Convert the Google Books API response into a simpler format.

    We do this because third-party API responses are often large and inconsistent.
    Our API should return a cleaner and more predictable structure.
    """
    volume_info = item.get("volumeInfo", {})
    authors = volume_info.get("authors", [])

    return {
        "id": item.get("id"),
        "title": volume_info.get("title"),
        "authors": authors,
        "published": volume_info.get("publishedDate"),
        "publisher": volume_info.get("publisher"),
        "description": volume_info.get("description"),
        "page_count": volume_info.get("pageCount"),
        "categories": volume_info.get("categories", []),
        "thumbnail": volume_info.get("imageLinks", {}).get("thumbnail"),
        "preview_link": volume_info.get("previewLink"),
        "info_link": volume_info.get("infoLink"),
    }


@app.get("/health")
def health_check() -> Dict[str, str]:
    """
    Health check endpoint.

    This is used by load balancers, orchestrators, and developers
    to verify that the service is up and responding.
    """
    return {"status": "ok"}


@app.get("/books")
def search_books(q: str = Query(..., min_length=1, description="Search term for books")) -> List[Dict[str, Any]]:
    """
    Search for books using the Google Books API.

    Example:
    GET /books?q=dune
    """
    try:
        response = requests.get(
            GOOGLE_BOOKS_BASE_URL,
            params={"q": q},
            timeout=10,
        )
        response.raise_for_status()
    except requests.RequestException as exc:
        raise HTTPException(
            status_code=502,
            detail=f"Failed to fetch data from Google Books API: {exc}",
        ) from exc

    data = response.json()
    items = data.get("items", [])

    return [simplify_book_data(item) for item in items]


@app.get("/books/{book_id}")
def get_book(book_id: str) -> Dict[str, Any]:
    """
    Get a single book by its Google Books volume ID.

    Example:
    GET /books/zyTCAlFPjgYC
    """
    try:
        response = requests.get(
            f"{GOOGLE_BOOKS_BASE_URL}/{book_id}",
            timeout=10,
        )
        if response.status_code == 404:
            raise HTTPException(status_code=404, detail="Book not found")

        response.raise_for_status()
    except HTTPException:
        raise
    except requests.RequestException as exc:
        raise HTTPException(
            status_code=502,
            detail=f"Failed to fetch data from Google Books API: {exc}",
        ) from exc

    data = response.json()
    return simplify_book_data(data)