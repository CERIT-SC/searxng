# SPDX-License-Identifier: AGPL-3.0-or-later
"""`Unpaywall`_ is a free database and tool that helps researchers find legal, 
open-access versions of scholarly articles. It searches across repositories 
and publishers to locate freely available full-text papers.

.. _Unpaywall: https://unpaywall.org/

Configuration
=============

.. code:: yaml

   - name: unpaywall
     engine: unpaywall
     shortcut: upw
     api_key: "you@your-domain.org"

     
Implementations
===============

"""

import typing as t

from datetime import datetime
from urllib.parse import quote, urlencode

from dateutil.parser import isoparse

from searx.exceptions import SearxEngineAPIException
from searx.result_types import EngineResults

if t.TYPE_CHECKING:
    from searx.extended_types import SXNG_Response
    from searx.search.processors import OnlineParams


about = {
    "website": "https://unpaywall.org/",
    "wikidata_id": "Q38352586",
    "official_api_documentation": "https://unpaywall.org/products/api",
    "use_official_api": True,
    "require_api_key": True,
    "results": "JSON",
}

categories = ["science", "scientific publications"]

# engine dependent config
paging = False
search_url = "https://api.unpaywall.org/v2"

# required by the Unpaywall API: set your email address in settings.yml (api_key)
api_key = None


def request(query: str, params: "OnlineParams") -> None:
    if not api_key:
        # the API requires an email address, without it it answers with 422
        raise SearxEngineAPIException("no email address configured (api_key)")

    # the query is the identifier (DOI or URL) and part of the path, so percent-encode it
    params["raise_for_httperror"] = False
    params["url"] = f"{search_url}/{quote(query.strip(), safe='')}?{urlencode({'email': api_key})}"


def response(resp: "SXNG_Response") -> EngineResults:
    res = EngineResults()

    if resp.status_code != 200:
        # 404: the identifier is no (known) DOI or URL
        return res

    item: dict[str, t.Any] = resp.json()

    # if there is no open access copy, Unpaywall has nothing to offer
    if not item.get("is_oa"):
        return res

    best_location: dict[str, t.Any] = item.get("best_oa_location") or {}
    landing_page: str = item.get("doi_url") or best_location.get("url_for_landing_page") or ""
    pdf_url: str = best_location.get("url_for_pdf") or ""
    url: str = pdf_url or best_location.get("url") or landing_page

    if not url:
        return res

    res.add(
        res.types.Paper(
            url=url,
            title=item.get("title", ""),
            journal=item.get("journal_name", ""),
            issn=_get_issns(item),
            authors=_get_authors(item),
            publisher=item.get("publisher", ""),
            doi=item.get("doi", ""),
            publishedDate=_get_published_date(item),
            type=item.get("genre", ""),
            comments=_get_comments(item),
            pdf_url=pdf_url,
            html_url=landing_page,
        )
    )

    return res


def _get_issns(item: dict[str, t.Any]) -> list[str]:
    """Extract the list of ISSNs from the comma separated ``journal_issns`` field."""
    return [issn.strip() for issn in item.get("journal_issns", "").split(",") if issn.strip()]


def _get_authors(item: dict[str, t.Any]) -> list[str]:
    """Extract the display names of the authors from the ``z_authors`` list."""
    return [
        author["raw_author_name"]
        for author in item.get("z_authors", [])
        if author.get("raw_author_name")
    ]


def _get_comments(item: dict[str, t.Any]) -> str:
    """Build a short comment about the open access status of the work."""
    license_name: str = (item.get("best_oa_location") or {}).get("license") or ""
    license_info = f", {license_name.upper()}" if license_name else ""
    return f"open access ({item.get('oa_status', '')}{license_info})"


def _get_published_date(item: dict[str, t.Any]) -> datetime | None:
    """Extract the published date from the item and convert it to a datetime object.

    Unpaywall may return ``YYYY``, ``YYYY-MM`` or ``YYYY-MM-DD``."""
    unformatted_date = item.get("published_date") or item.get("year")
    if unformatted_date:
        return isoparse(str(unformatted_date))
    return None
