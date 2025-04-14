const express = require('express');
const SSI = require('node-ssi');
const path = require('path');
const fs = require('fs');

const app = express();
const port = 3000;

// Initialize SSI processor for ui-designs directory
const ssi = new SSI({
  baseDir: path.join(__dirname, 'ui-designs'),
  encoding: 'utf-8',
  payload: {/* Data to pass to includes */}
});

// Serve the root directory as ui-designs/index-standalone.html
app.get('/', (req, res) => {
  res.redirect('/ui-designs/index-standalone.html');
});

// Handle SSI processing for HTML files in the ui-designs directory
app.use('/ui-designs', (req, res, next) => {
  if (req.path.endsWith('.html')) {
    const filePath = path.join(__dirname, 'ui-designs', req.path);
    
    // Check if file exists
    if (!fs.existsSync(filePath)) {
      return res.status(404).send('File not found: ' + req.path);
    }
    
    // Process SSI directives
    ssi.compileFile(filePath, (err, content) => {
      if (err) {
        console.error('SSI Error:', err);
        return res.status(500).send('Error processing SSI directives: ' + err.message);
      }
      res.setHeader('Content-Type', 'text/html');
      res.send(content);
    });
  } else {
    next();
  }
});

// Serve static files
app.use(express.static(__dirname));

app.listen(port, () => {
  console.log(`Design system server running at http://localhost:${port}`);
  console.log(`Home page: http://localhost:${port}`);
  console.log(`View standalone version: http://localhost:${port}/ui-designs/index-standalone.html`);
  console.log(`View SSI version: http://localhost:${port}/ui-designs/index.html`);
}); 