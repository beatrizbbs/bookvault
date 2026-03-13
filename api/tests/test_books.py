from typing import Any, Dict

import requests
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


class MockResponse:
    def __init__(self, json_data: Dict[str, Any], status_code: int = 200):
        self._json_data = json_data
        self.status_code = status_code

    def json(self) -> Dict[str, Any]:
        return self._json_data

    def raise_for_status(self) -> None:
        if self.status_code >= 400:
            raise requests.HTTPError(f"HTTP error: {self.status_code}")


def test_search_books(monkeypatch):
    mock_google_response = {
        "items": [
            {
                "id": "acotar123",
                "volumeInfo": {
                    "title": "A Court of Thorns and Roses",
                    "authors": ["Sarah J. Maas"],
                    "publishedDate": "2015",
                    "publisher": "Bloomsbury Publishing",
                    "description": "A fantasy romance novel.",
                    "pageCount": 432,
                    "categories": ["Fantasy", "Romance"],
                    "imageLinks": {
                        "thumbnail": "https://example.com/acotar.jpg"
                    },
                    "previewLink": "https://example.com/acotar-preview",
                    "infoLink": "https://example.com/acotar-info",
                },
            },
            {
                "id": "caraval456",
                "volumeInfo": {
                    "title": "Caraval",
                    "authors": ["Stephanie Garber"],
                    "publishedDate": "2017",
                    "publisher": "Flatiron Books",
                    "description": "A magical competition full of mystery.",
                    "pageCount": 416,
                    "categories": ["Fantasy", "Young Adult"],
                    "imageLinks": {
                        "thumbnail": "https://example.com/caraval.jpg"
                    },
                    "previewLink": "https://example.com/caraval-preview",
                    "infoLink": "https://example.com/caraval-info",
                },
            },
            {
                "id": "shatterme789",
                "volumeInfo": {
                    "title": "Shatter Me",
                    "authors": ["Tahereh Mafi"],
                    "publishedDate": "2011",
                    "publisher": "HarperCollins",
                    "description": "A dystopian story with dangerous powers.",
                    "pageCount": 352,
                    "categories": ["Dystopian", "Young Adult"],
                    "imageLinks": {
                        "thumbnail": "https://example.com/shatterme.jpg"
                    },
                    "previewLink": "https://example.com/shatterme-preview",
                    "infoLink": "https://example.com/shatterme-info",
                },
            },
        ]
    }

    def mock_get(*args, **kwargs):
        return MockResponse(mock_google_response, 200)

    monkeypatch.setattr("app.main.requests.get", mock_get)

    response = client.get("/books?q=fantasy")

    assert response.status_code == 200

    data = response.json()
    assert isinstance(data, list)
    assert len(data) == 3

    assert data[0]["title"] == "A Court of Thorns and Roses"
    assert data[0]["authors"] == ["Sarah J. Maas"]
    assert data[1]["title"] == "Caraval"
    assert data[2]["title"] == "Shatter Me"


def test_get_book_by_id(monkeypatch):
    mock_google_response = {
        "id": "acotar123",
        "volumeInfo": {
            "title": "A Court of Thorns and Roses",
            "authors": ["Sarah J. Maas"],
            "publishedDate": "2015",
            "publisher": "Bloomsbury Publishing",
            "description": "A fantasy romance novel.",
            "pageCount": 432,
            "categories": ["Fantasy", "Romance"],
            "imageLinks": {
                "thumbnail": "https://example.com/acotar.jpg"
            },
            "previewLink": "https://example.com/acotar-preview",
            "infoLink": "https://example.com/acotar-info",
        },
    }

    def mock_get(*args, **kwargs):
        return MockResponse(mock_google_response, 200)

    monkeypatch.setattr("app.main.requests.get", mock_get)

    response = client.get("/books/acotar123")

    assert response.status_code == 200

    data = response.json()
    assert data["id"] == "acotar123"
    assert data["title"] == "A Court of Thorns and Roses"
    assert data["authors"] == ["Sarah J. Maas"]
    assert data["published"] == "2015"


def test_search_books_requires_query():
    response = client.get("/books")

    assert response.status_code == 422
    
def test_search_books_returns_empty_list_when_no_results(monkeypatch):
    mock_google_response = {
        "items": []
    }

    def mock_get(*args, **kwargs):
        return MockResponse(mock_google_response, 200)

    monkeypatch.setattr("app.main.requests.get", mock_get)

    response = client.get("/books?q=some-very-obscure-book-query")

    assert response.status_code == 200
    assert response.json() == []
    
def test_search_books_returns_502_when_google_books_fails(monkeypatch):
    def mock_get(*args, **kwargs):
        raise requests.RequestException("Google Books API is unavailable")

    monkeypatch.setattr("app.main.requests.get", mock_get)

    response = client.get("/books?q=dune")

    assert response.status_code == 502
    assert "Failed to fetch data from Google Books API" in response.json()["detail"]
    
def test_get_book_returns_404_when_book_is_not_found(monkeypatch):
    def mock_get(*args, **kwargs):
        return MockResponse({}, 404)

    monkeypatch.setattr("app.main.requests.get", mock_get)

    response = client.get("/books/unknown-book-id")

    assert response.status_code == 404
    assert response.json() == {"detail": "Book not found"}