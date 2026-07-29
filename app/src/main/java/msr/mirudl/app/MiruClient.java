package msr.mirudl.app;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.IOException;
import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.TimeUnit;

import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;

public class MiruClient {
    public static final String BASE = "https://anidb.app";
    private static final String UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36";
    private static final int TIMEOUT = 30;
    private static MiruClient instance;

    private final OkHttpClient client;

    private MiruClient() {
        client = new OkHttpClient.Builder()
                .connectTimeout(TIMEOUT, TimeUnit.SECONDS)
                .readTimeout(TIMEOUT, TimeUnit.SECONDS)
                .followRedirects(true)
                .followSslRedirects(true)
                .build();
    }

    public static synchronized MiruClient getInstance() {
        if (instance == null) instance = new MiruClient();
        return instance;
    }

    // ============ SEARCH ============

    public List<AnimeItem> search(String query) throws Exception {
        String url = BASE + "/search/suggestions?q=" + encode(query);
        String html = getHtml(url);
        return parseSearchResults(html);
    }

    private List<AnimeItem> parseSearchResults(String html) {
        List<AnimeItem> results = new ArrayList<>();
        // Parse search results
        int idx = 0;
        while (true) {
            int aStart = html.indexOf("<a ", idx);
            if (aStart < 0) break;
            int aEnd = html.indexOf("</a>", aStart);
            if (aEnd < 0) break;
            String block = html.substring(aStart, aEnd);

            if (block.contains("data-search-item")) {
                AnimeItem item = new AnimeItem();
                // Extract href
                int hrefIdx = block.indexOf("href=\"");
                if (hrefIdx >= 0) {
                    int hrefEnd = block.indexOf("\"", hrefIdx + 6);
                    if (hrefEnd > 0) {
                        item.url = block.substring(hrefIdx + 6, hrefEnd);
                        String[] parts = item.url.split("-");
                        item.id = parts[parts.length - 1];
                    }
                }
                // Extract title
                int titleStart = block.indexOf("line-clamp-1\">");
                if (titleStart >= 0) {
                    int titleEnd = block.indexOf("</p>", titleStart);
                    if (titleEnd > 0) {
                        item.title = block.substring(titleStart + 14, titleEnd).trim();
                        item.title = android.text.Html.fromHtml(item.title).toString();
                    }
                }
                // Extract poster
                int imgIdx = block.indexOf("src=\"");
                if (imgIdx >= 0) {
                    int imgEnd = block.indexOf("\"", imgIdx + 5);
                    if (imgEnd > 0) {
                        item.thumbnail = block.substring(imgIdx + 5, imgEnd);
                    }
                }
                if (item.id != null) results.add(item);
            }
            idx = aEnd + 4;
        }
        return results;
    }

    // ============ EPISODES ============

    public List<EpisodeItem> getEpisodes(String animeId) throws Exception {
        String url = BASE + "/api/frontend/anime/" + animeId + "/episodes";
        String json = get(url);
        JSONObject obj = new JSONObject(json);
        JSONArray arr = obj.getJSONArray("episodes");
        List<EpisodeItem> episodes = new ArrayList<>();
        for (int i = 0; i < arr.length(); i++) {
            JSONObject ep = arr.getJSONObject(i);
            EpisodeItem item = new EpisodeItem();
            item.id = ep.getInt("id");
            item.number = ep.getInt("number");
            item.number2 = ep.optInt("number2", 0);
            item.filler = ep.optBoolean("filler", false);
            episodes.add(item);
        }
        return episodes;
    }

    // ============ EMBED / HLS ============

    public List<VideoSource> getEpisodeLanguages(int episodeId) throws Exception {
        String url = BASE + "/api/frontend/episode/" + episodeId + "/languages";
        String json = get(url);
        JSONObject obj = new JSONObject(json);
        JSONArray arr = obj.getJSONArray("languages");
        List<VideoSource> sources = new ArrayList<>();
        for (int i = 0; i < arr.length(); i++) {
            JSONObject lang = arr.getJSONObject(i);
            VideoSource vs = new VideoSource(
                    lang.optString("name", "Source"),
                    lang.optString("embed_url", ""),
                    lang.optString("code", "jpn"),
                    "MiruDL"
            );
            sources.add(vs);
        }
        return sources;
    }

    public String resolveHlsFromEmbed(String embedUrl) throws Exception {
        String html = getHtml(embedUrl);
        // Match file: '...master.m3u8' or file: "...master.m3u8"
        int fileIdx = html.indexOf("file:");
        if (fileIdx < 0) return null;
        int quoteStart = html.indexOf("'", fileIdx);
        if (quoteStart < 0) quoteStart = html.indexOf("\"", fileIdx);
        if (quoteStart < 0) quoteStart = html.indexOf("`", fileIdx);
        if (quoteStart < 0) return null;
        char quote = html.charAt(quoteStart);
        int quoteEnd = html.indexOf(quote, quoteStart + 1);
        if (quoteEnd < 0) return null;
        return html.substring(quoteStart + 1, quoteEnd);
    }

    // ============ HLS QUALITIES ============

    public List<VideoSource> getQualities(String masterUrl) throws Exception {
        String playlist = get(masterUrl);
        List<VideoSource> variants = new ArrayList<>();
        String pendingLine = null;
        for (String raw : playlist.split("\\r?\\n")) {
            String line = raw.trim();
            if (line.startsWith("#EXT-X-STREAM-INF")) {
                pendingLine = line;
            } else if (pendingLine != null && !line.isEmpty() && !line.startsWith("#")) {
                String quality = extractResolution(pendingLine);
                String url = resolveUrl(line, masterUrl);
                variants.add(new VideoSource(quality, url));
                pendingLine = null;
            }
        }
        if (variants.isEmpty()) {
            variants.add(new VideoSource("Auto", masterUrl));
        }
        return variants;
    }

    // ============ HTTP ============

    private String get(String url) throws Exception {
        Request request = new Request.Builder()
                .url(url)
                .header("User-Agent", UA)
                .header("Accept", "application/json")
                .header("X-Requested-With", "XMLHttpRequest")
                .header("Referer", BASE + "/")
                .build();
        try (Response response = client.newCall(request).execute()) {
            if (!response.isSuccessful() || response.body() == null)
                throw new IOException("HTTP " + response.code());
            return response.body().string();
        }
    }

    private String getHtml(String url) throws Exception {
        Request request = new Request.Builder()
                .url(url)
                .header("User-Agent", UA)
                .header("Accept", "text/html,*/*")
                .header("Referer", BASE + "/")
                .build();
        try (Response response = client.newCall(request).execute()) {
            if (!response.isSuccessful() || response.body() == null)
                throw new IOException("HTTP " + response.code());
            return response.body().string();
        }
    }

    // ============ BROWSE ============

    public List<AnimeItem> browseCurrentlyAiring() throws Exception {
        String url = BASE + "/browse?sort=order_top_airing&status=Currently+Airing";
        String html = getHtml(url);
        return parseBrowseResults(html);
    }

    private List<AnimeItem> parseBrowseResults(String html) {
        List<AnimeItem> results = new ArrayList<>();
        // Look for anime links: /anime/{slug-id}
        int idx = 0;
        while (true) {
            int linkStart = html.indexOf("/anime/", idx);
            if (linkStart < 0) break;

            // Find wrapping <a tag
            int aStart = html.lastIndexOf("<a ", linkStart);
            if (aStart < 0 || aStart < idx - 50) {
                idx = linkStart + 7;
                continue;
            }

            int aEnd = html.indexOf("</a>", linkStart);
            if (aEnd < 0) break;

            String block = html.substring(aStart, aEnd + 4);
            AnimeItem item = new AnimeItem();

            // URL + ID from /anime/slug-id
            int hrefEnd = html.indexOf("\"", linkStart + 7);
            if (hrefEnd > linkStart) {
                item.url = BASE + html.substring(linkStart, hrefEnd);
                String slugPart = item.url.startsWith("/anime/") ? item.url.substring(7) : item.url;
                String[] parts = slugPart.split("-");
                item.id = parts.length > 0 ? parts[parts.length - 1] : null;
            }

            // Title from img alt
            int altIdx = block.indexOf("alt=\"");
            if (altIdx >= 0) {
                altIdx += 5;
                int altEnd = block.indexOf("\"", altIdx);
                if (altEnd > altIdx) {
                    String alt = block.substring(altIdx, altEnd).trim();
                    if (!alt.isEmpty() && !alt.toLowerCase().contains("thumbnail")
                            && !alt.toLowerCase().contains("poster")) {
                        item.title = android.text.Html.fromHtml(alt).toString();
                    }
                }
            }

            // Fallback: h2/h3/p text
            if (item.title == null || item.title.isEmpty()) {
                java.util.regex.Matcher m = java.util.regex.Pattern.compile(
                        "<(h[23]|p)\\b[^>]*>(.*?)</\\1>",
                        java.util.regex.Pattern.DOTALL).matcher(block);
                if (m.find()) {
                    String t = android.text.Html.fromHtml(m.group(2)).toString().trim();
                    if (!t.isEmpty() && t.length() < 100) item.title = t;
                }
            }
            if (item.title == null) item.title = "";

            // Poster image
            int imgIdx = block.indexOf("src=\"");
            if (imgIdx >= 0) {
                imgIdx += 5;
                int imgEnd = block.indexOf("\"", imgIdx);
                if (imgEnd > imgIdx) {
                    String src = block.substring(imgIdx, imgEnd);
                    if (!src.startsWith("http")) {
                        src = (src.startsWith("/") ? BASE : BASE + "/") + src;
                    }
                    item.thumbnail = src;
                }
            }

            if (item.id != null && !item.title.isEmpty()) {
                boolean dup = false;
                for (AnimeItem ex : results) {
                    if (ex.id != null && ex.id.equals(item.id)) { dup = true; break; }
                }
                if (!dup) results.add(item);
            }

            idx = aEnd + 4;
        }
        return results;
    }

    // ============ HELPERS ============

    private String encode(String value) {
        try {
            return URLEncoder.encode(value, "UTF-8");
        } catch (Exception e) {
            return value;
        }
    }

    private String extractResolution(String infLine) {
        int resIdx = infLine.indexOf("RESOLUTION=");
        if (resIdx >= 0) {
            int end = infLine.indexOf(",", resIdx);
            if (end < 0) end = infLine.length();
            return infLine.substring(resIdx + 11, end);
        }
        int bwIdx = infLine.indexOf("BANDWIDTH=");
        if (bwIdx >= 0) {
            int end = infLine.indexOf(",", bwIdx);
            if (end < 0) end = infLine.length();
            return infLine.substring(bwIdx + 10, end) + "bps";
        }
        return "Auto";
    }

    private String resolveUrl(String value, String base) {
        if (value.startsWith("http://") || value.startsWith("https://")) return value;
        if (value.startsWith("/")) {
            int slash = base.indexOf("/", 8);
            return (slash > 0 ? base.substring(0, slash) : base) + value;
        }
        int slash = base.lastIndexOf("/");
        return (slash > 0 ? base.substring(0, slash + 1) : base + "/") + value;
    }


    
    // ============ ANIME DETAILS ============


    public List<EpisodeItem> getEpisodesWithSeasons(String animeId) throws Exception {
        return getEpisodes(animeId);
    }

    public String getAnimeTitle(String animeId) throws Exception {
        try {
                        String url;
            if (animeId != null String url = animeId != null && animeId.startsWith("http") ? animeId : BASE + "/anime/" + animeId;String url = animeId != null && animeId.startsWith("http") ? animeId : BASE + "/anime/" + animeId; animeId.startsWith("http")) {
                url = animeId;
            } else if (animeId != null String url = animeId != null && animeId.startsWith("http") ? animeId : BASE + "/anime/" + animeId;String url = animeId != null && animeId.startsWith("http") ? animeId : BASE + "/anime/" + animeId; animeId.startsWith("/")) {
                url = BASE + animeId;
            } else {
                url = BASE + "/anime/" + animeId;
            }
            String html = getHtml(url);
            int titleStart = html.indexOf("property=\"og:title\" content=\"");
            if (titleStart >= 0) {
                titleStart += 32;
                int titleEnd = html.indexOf("\"", titleStart);
                if (titleEnd > 0) return html.substring(titleStart, titleEnd);
            }
            String url;
            if (animeUrl != null && animeUrl.startsWith("http")) {
                url = animeUrl;
            } else if (animeUrl != null && animeUrl.startsWith("/")) {
                url = BASE + animeUrl;
            } else {
                result.put("id", animeUrl != null ? animeUrl : "");
                return result;
            }
    /** Scrape anime details from the HTML page using the full anime URL (with slug). */
    public JSONObject getAnimeDetails(String animeUrl) throws Exception {
        JSONObject result = new JSONObject();
        try {
            // Fetch the anime page HTML using the full URL (e.g. https://anidb.app/anime/naruto-3686)
            String url = animeUrl;
            if (url == null || url.isEmpty()) {
                result.put("id", "");
                return result;
            }
            String html = getHtml(url);

            // Extract description from meta description or og:description
            String desc = "";
            int descIdx = html.indexOf("<meta name=\"description\" content=\"");
            if (descIdx < 0) descIdx = html.indexOf("<meta property=\"og:description\" content=\"");
            if (descIdx >= 0) {
                descIdx = html.indexOf("content=\"", descIdx) + 9;
                int descEnd = html.indexOf("\"", descIdx);
                if (descEnd > descIdx) {
                    desc = android.text.Html.fromHtml(html.substring(descIdx, descEnd)).toString();
                }
            }
            if (!desc.isEmpty()) result.put("description", desc);

            // Extract full description from the page body (more complete text)
            int fullDescIdx = html.indexOf("class=\"text-sm text-faint leading-relaxed\">");
            if (fullDescIdx >= 0) {
                fullDescIdx += 47;
                int fullDescEnd = html.indexOf("</div>", fullDescIdx);
                if (fullDescEnd > fullDescIdx) {
                    String fullDesc = html.substring(fullDescIdx, fullDescEnd);
                    fullDesc = android.text.Html.fromHtml(fullDesc).toString().trim();
                    if (!fullDesc.isEmpty()) result.put("description", fullDesc);
                }
            }

            // Extract type (TV, Movie, OVA etc.) from first anime badge
            int badgeIdx = 0;
            int count = 0;
            while (badgeIdx >= 0 && count < 10) {
                badgeIdx = html.indexOf("<span class=\"badge", badgeIdx);
                if (badgeIdx < 0) break;
                int closeIdx = html.indexOf(">", badgeIdx);
                if (closeIdx < 0) break;
                closeIdx++;
                int endIdx = html.indexOf("</span>", closeIdx);
                if (endIdx < 0) break;
                String badgeText = html.substring(closeIdx, endIdx).trim();
                badgeIdx = endIdx + 6;
                count++;
                // Skip nav/browse badges, only consider relevant type badges
                if (badgeText.matches("TV|Movie|OVA|ONA|Special|Music")) {
                    result.put("type", badgeText);
                    break;
                }
            }

            // Extract year
            java.util.regex.Matcher yearMatcher = java.util.regex.Pattern.compile(">(\\d{4})<").matcher(html);
            while (yearMatcher.find()) {
                int y = Integer.parseInt(yearMatcher.group(1));
                if (y > 1950 && y < 2030) {
                    result.put("year", String.valueOf(y));
                    break;
                }
            }

            // Extract rating
            java.util.regex.Matcher ratingMatcher = java.util.regex.Pattern.compile(">([0-9]\\.[0-9])<").matcher(html);
            if (ratingMatcher.find()) {
                result.put("rating", ratingMatcher.group(1));
            }

            // Extract genre from JSON-LD
            int ldIdx = html.indexOf("application/ld+json");
            if (ldIdx >= 0) {
                int ldStart = html.indexOf("{", ldIdx);
                int ldEnd = html.indexOf("</script>", ldIdx);
                if (ldStart >= 0 && ldEnd > ldStart) {
                    String ldRaw = html.substring(ldStart, ldEnd);
                    ldRaw = ldRaw.replace("&quot;", "\"").replace("&#039;", "'")
                                 .replace("&amp;", "&").replace("&lt;", "<").replace("&gt;", ">");
                    JSONObject ldJson = new JSONObject(ldRaw);
                    if (ldJson.has("genre")) {
                        Object genre = ldJson.get("genre");
                        if (genre instanceof org.json.JSONArray) {
                            result.put("genres", genre);
                        }
                    }
                    // Status from description or JSON-LD
                    if (ldJson.has("description")) {
                        String d = ldJson.optString("description", "");
                        if (!d.isEmpty() && !result.has("description")) {
                            result.put("description", d);
                        }
                    }
                }
            }

            // Build meta string: "type · year · episodes"
            StringBuilder meta = new StringBuilder();
            if (result.has("type")) meta.append(result.getString("type"));
            if (result.has("year")) {
                if (meta.length() > 0) meta.append(" · ");
                meta.append(result.getString("year"));
            }
            if (result.has("rating")) {
                if (meta.length() > 0) meta.append(" · ");
                meta.append("★ ").append(result.getString("rating"));
            }
            if (meta.length() > 0) result.put("meta", meta.toString());

        } catch (Exception e) {
            result.put("id", animeUrl != null ? animeUrl : "");
        }
        return result;
    }
}
