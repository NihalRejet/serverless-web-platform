// ---------------------------------------------------------------------------
// STAGE 7 TODO: replace API_BASE with the real API Gateway endpoint.
//
//   cd infra && terraform output -raw api_endpoint
//
// It looks like: https://a1b2c3d4e5.execute-api.ap-south-1.amazonaws.com
// Until then the page shows the error state, which is expected.
// ---------------------------------------------------------------------------
const API_BASE = "https://h7xmrodgl0.execute-api.ap-south-1.amazonaws.com";

// The Lambda must answer GET /count with JSON shaped like: { "count": 42 }
const COUNT_PATH = "/count";

const countEl = document.getElementById("count");

function render(text, state) {
  countEl.textContent = text;
  countEl.className = state ? "count " + state : "count";
}

async function loadCount() {
  try {
    const response = await fetch(API_BASE + COUNT_PATH);

    // fetch() only rejects on a network failure, so a 404 or 500 still lands
    // here as a resolved promise. Check the status explicitly.
    if (!response.ok) {
      throw new Error("API returned HTTP " + response.status);
    }

    const data = await response.json();

    if (typeof data.count !== "number") {
      throw new Error("Response had no numeric 'count' field");
    }

    render(data.count.toLocaleString(), null);
  } catch (error) {
    // Log the real reason for debugging, show something calm on the page.
    console.error("Could not load the visit count:", error);
    render("Unavailable", "error");
  }
}

loadCount();
