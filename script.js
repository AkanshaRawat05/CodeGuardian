let allIssues = [];
let filteredIssues = [];
let currentPage = 1;
const pageSize = 5;
let currentSort = { column: 'line', ascending: true };

function uploadFile() {
  const fileInput = document.getElementById("fileInput");
  const file = fileInput.files[0];

  if (!file) {
    alert("Please select a C file to upload.");
    return;
  }

  const formData = new FormData();
  formData.append("file", file);

  fetch("http://127.0.0.1:5000/upload", {
    method: "POST",
    body: formData,
  })
    .then(response => {
      if (!response.ok) {
        throw new Error("Upload failed");
      }
      return response.json();
    })
    .then(data => {
      console.log("Received:", data); // Debug line
      displayResults(data);
    })
    .catch(error => {
      console.error("Error:", error);
      alert("Failed to upload and analyze the file.");
    });
}


function downloadCsv() {
  const table = document.getElementById("issuesTable");
  const rows = table.querySelectorAll("tr");
  let csvContent = "";

  rows.forEach((row, index) => {
    const cols = row.querySelectorAll("th, td");
    const rowData = [];

    cols.forEach((col, colIndex) => {
      let text = "";

      // For the Reference Link column (last column), grab href instead of text
      if (col.querySelector("a")) {
        text = col.querySelector("a").href;
      } else {
        text = col.innerText;
      }

      // Escape quotes and commas in text
      text = text.replace(/"/g, '""');
      if (text.includes(",") || text.includes("\n")) {
        text = `"${text}"`;
      }
      rowData.push(text);
    });

    csvContent += rowData.join(",") + "\n";
  });

  const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = "code_analysis_issues.csv";
  a.style.display = "none";
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}



function displayResults(data) {
  const table = document.getElementById("issuesTable");
  const tbody = table.querySelector("tbody");
  const noIssues = document.getElementById("noIssues");
  const downloadBtn = document.getElementById("downloadCsvBtn");
  
  tbody.innerHTML = ""; // clear old rows
  table.style.display = "none";
  noIssues.style.display = "none";
  downloadBtn.style.display = "none"; // hide initially

  if (!data.issues || data.issues.length === 0) {
    noIssues.style.display = "block";
    return;
  }

  data.issues.forEach(issue => {
    const tr = document.createElement("tr");

    let severityClass = "";
    if (issue.severity.toLowerCase() === "warning") severityClass = "warning";
    else if (issue.severity.toLowerCase() === "error") severityClass = "error";
    else if (issue.severity.toLowerCase() === "info") severityClass = "info";

    tr.innerHTML = `
      <td>${issue.line}</td>
      <td class="${severityClass}">${issue.severity}</td>
      <td>${issue.message}</td>
      <td><a href="${issue.reference}" target="_blank" rel="noopener noreferrer">Reference</a></td>
    `;

    tbody.appendChild(tr);
  });

  table.style.display = "table";
  downloadBtn.style.display = "inline-block";

  // Attach click event for CSV download
  downloadBtn.onclick = downloadCsv;
}
