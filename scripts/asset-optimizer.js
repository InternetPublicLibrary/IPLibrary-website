#!/usr/bin/env node

/**
 * Asset Optimization Pipeline
 * Comprehensive asset optimization for CSS/JS minification, image optimization, and fingerprinting
 */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { execSync } = require('child_process');
const { promisify } = require('util');
const glob = require('glob');

// Configuration
const CONFIG = {
  // Directories
  sourceDir: process.cwd(),
  buildDir: '_site',
  assetsDir: 'assets',
  tempDir: '.tmp',
  
  // Asset types
  assetTypes: {
    css: {
      extensions: ['.css'],
      outputDir: 'css',
      minify: true,
      fingerprint: true,
      sourcemap: true
    },
    js: {
      extensions: ['.js'],
      outputDir: 'js',
      minify: true,
      fingerprint: true,
      sourcemap: true,
      bundle: true
    },
    images: {
      extensions: ['.jpg', '.jpeg', '.png', '.gif', '.svg', '.webp'],
      outputDir: 'images',
      optimize: true,
      webp: true,
      fingerprint: false // Images are usually content-static
    },
    fonts: {
      extensions: ['.woff', '.woff2', '.ttf', '.eot'],
      outputDir: 'fonts',
      fingerprint: false
    }
  },
  
  // Optimization settings
  optimization: {
    css: {
      level: 2,
      compatibility: 'ie8',
      removeComments: true,
      removeDuplicateRules: true
    },
    js: {
      mangle: true,
      compress: {
        drop_console: process.env.NODE_ENV === 'production',
        drop_debugger: true,
        pure_funcs: ['console.log', 'console.debug']
      }
    },
    images: {
      quality: 85,
      webpQuality: 80,
      progressive: true,
      optimizationLevel: 3
    }
  },
  
  // Jekyll integration
  jekyll: {
    configFile: '_config.yml',
    assetsPath: '/assets',
    fingerprintFile: '_data/assets.yml'
  }
};

class AssetOptimizer {
  constructor(config = CONFIG) {
    this.config = config;
    this.assetMap = new Map();
    this.fingerprintMap = new Map();
    this.stats = {
      processed: 0,
      optimized: 0,
      errors: 0,
      sizeBefore: 0,
      sizeAfter: 0
    };
  }

  async optimize(options = {}) {
    const { 
      mode = 'production', 
      watch = false, 
      verbose = false,
      types = Object.keys(this.config.assetTypes)
    } = options;

    console.log(`🚀 Starting asset optimization in ${mode} mode...`);
    
    try {
      // Create directories
      await this.createDirectories();
      
      // Process each asset type
      for (const type of types) {
        if (this.config.assetTypes[type]) {
          await this.processAssetType(type, mode, verbose);
        }
      }
      
      // Generate asset fingerprint map
      await this.generateAssetMap();
      
      // Update HTML references
      await this.updateHtmlReferences();
      
      // Output statistics
      this.outputStats();
      
      if (watch) {
        await this.startWatcher();
      }
      
    } catch (error) {
      console.error('❌ Asset optimization failed:', error);
      process.exit(1);
    }
  }

  async createDirectories() {
    const dirs = [
      this.config.tempDir,
      path.join(this.config.buildDir, this.config.assetsDir),
      ...Object.values(this.config.assetTypes).map(type => 
        path.join(this.config.buildDir, this.config.assetsDir, type.outputDir)
      )
    ];

    for (const dir of dirs) {
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
      }
    }
  }

  async processAssetType(type, mode, verbose) {
    const typeConfig = this.config.assetTypes[type];
    const extensions = typeConfig.extensions.join(',');
    
    console.log(`📁 Processing ${type} assets...`);
    
    // Find all files of this type
    const pattern = `**/*{${extensions}}`;
    const files = glob.sync(pattern, {
      cwd: this.config.sourceDir,
      ignore: [
        '_site/**',
        'node_modules/**',
        'vendor/**',
        '.git/**',
        '.tmp/**'
      ]
    });

    if (verbose) {
      console.log(`   Found ${files.length} ${type} files`);
    }

    for (const file of files) {
      try {
        await this.processFile(file, type, mode);
        this.stats.processed++;
      } catch (error) {
        console.error(`   ❌ Error processing ${file}:`, error.message);
        this.stats.errors++;
      }
    }
  }

  async processFile(filePath, type, mode) {
    const typeConfig = this.config.assetTypes[type];
    const sourcePath = path.join(this.config.sourceDir, filePath);
    const fileName = path.basename(filePath);
    const fileContent = fs.readFileSync(sourcePath);
    
    this.stats.sizeBefore += fileContent.length;
    
    let processedContent = fileContent;
    let outputPath = path.join(this.config.buildDir, this.config.assetsDir, typeConfig.outputDir, fileName);
    
    // Process based on asset type
    switch (type) {
      case 'css':
        processedContent = await this.processCss(fileContent, mode);
        break;
      case 'js':
        processedContent = await this.processJavaScript(fileContent, mode);
        break;
      case 'images':
        processedContent = await this.processImage(sourcePath, mode);
        break;
      case 'fonts':
        // Fonts are copied as-is
        break;
    }
    
    // Apply fingerprinting if enabled
    if (typeConfig.fingerprint && mode === 'production') {
      const hash = this.generateHash(processedContent);
      const ext = path.extname(fileName);
      const name = path.basename(fileName, ext);
      const fingerprintedName = `${name}-${hash}${ext}`;
      
      outputPath = path.join(this.config.buildDir, this.config.assetsDir, typeConfig.outputDir, fingerprintedName);
      
      // Store fingerprint mapping
      this.fingerprintMap.set(filePath, {
        original: fileName,
        fingerprinted: fingerprintedName,
        hash: hash,
        path: `${this.config.jekyll.assetsPath}/${typeConfig.outputDir}/${fingerprintedName}`
      });
    }
    
    // Write processed file
    fs.writeFileSync(outputPath, processedContent);
    
    this.stats.sizeAfter += processedContent.length;
    this.stats.optimized++;
  }

  async processCss(content, mode) {
    if (mode !== 'production') {
      return content;
    }

    try {
      const CleanCSS = require('clean-css');
      const cleanCSS = new CleanCSS(this.config.optimization.css);
      const result = cleanCSS.minify(content);
      
      if (result.errors.length > 0) {
        throw new Error(`CSS optimization failed: ${result.errors.join(', ')}`);
      }
      
      return result.styles;
    } catch (error) {
      console.warn('   ⚠️  CSS minification failed, using original:', error.message);
      return content;
    }
  }

  async processJavaScript(content, mode) {
    if (mode !== 'production') {
      return content;
    }

    try {
      const terser = require('terser');
      const result = await terser.minify(content.toString(), {
        ...this.config.optimization.js,
        sourceMap: this.config.assetTypes.js.sourcemap
      });
      
      if (result.error) {
        throw new Error(`JavaScript optimization failed: ${result.error}`);
      }
      
      return result.code;
    } catch (error) {
      console.warn('   ⚠️  JavaScript minification failed, using original:', error.message);
      return content;
    }
  }

  async processImage(sourcePath, mode) {
    if (mode !== 'production' || !this.config.assetTypes.images.optimize) {
      return fs.readFileSync(sourcePath);
    }

    try {
      const sharp = require('sharp');
      const ext = path.extname(sourcePath).toLowerCase();
      
      let pipeline = sharp(sourcePath);
      
      // Optimize based on format
      switch (ext) {
        case '.jpg':
        case '.jpeg':
          pipeline = pipeline.jpeg({
            quality: this.config.optimization.images.quality,
            progressive: this.config.optimization.images.progressive
          });
          break;
        case '.png':
          pipeline = pipeline.png({
            compressionLevel: this.config.optimization.images.optimizationLevel
          });
          break;
        case '.webp':
          pipeline = pipeline.webp({
            quality: this.config.optimization.images.webpQuality
          });
          break;
        default:
          // For other formats, return original
          return fs.readFileSync(sourcePath);
      }
      
      return await pipeline.toBuffer();
    } catch (error) {
      console.warn('   ⚠️  Image optimization failed, using original:', error.message);
      return fs.readFileSync(sourcePath);
    }
  }

  generateHash(content) {
    return crypto.createHash('md5').update(content).digest('hex').slice(0, 8);
  }

  async generateAssetMap() {
    const assetMapPath = path.join(this.config.sourceDir, '_data');
    
    if (!fs.existsSync(assetMapPath)) {
      fs.mkdirSync(assetMapPath, { recursive: true });
    }
    
    const assetData = {};
    
    for (const [filePath, fingerprint] of this.fingerprintMap) {
      const key = filePath.replace(/[^a-zA-Z0-9]/g, '_');
      assetData[key] = {
        original: fingerprint.original,
        fingerprinted: fingerprint.fingerprinted,
        hash: fingerprint.hash,
        path: fingerprint.path
      };
    }
    
    // Write YAML file for Jekyll
    const yamlPath = path.join(assetMapPath, 'assets.yml');
    const yamlData = Object.entries(assetData)
      .map(([key, data]) => `${key}:\n  original: "${data.original}"\n  fingerprinted: "${data.fingerprinted}"\n  hash: "${data.hash}"\n  path: "${data.path}"`)
      .join('\n\n');
    
    fs.writeFileSync(yamlPath, yamlData);
    
    // Also write JSON for JavaScript access
    const jsonPath = path.join(this.config.buildDir, 'assets', 'manifest.json');
    fs.writeFileSync(jsonPath, JSON.stringify(assetData, null, 2));
    
    console.log(`📋 Generated asset manifest with ${Object.keys(assetData).length} fingerprinted assets`);
  }

  async updateHtmlReferences() {
    const htmlPattern = path.join(this.config.buildDir, '**/*.html');
    const htmlFiles = glob.sync(htmlPattern);
    
    let updatedFiles = 0;
    
    for (const htmlFile of htmlFiles) {
      let content = fs.readFileSync(htmlFile, 'utf8');
      let updated = false;
      
      // Update CSS references
      for (const [filePath, fingerprint] of this.fingerprintMap) {
        const originalPath = `/assets/${path.dirname(filePath)}/${fingerprint.original}`;
        const fingerprintedPath = fingerprint.path;
        
        if (content.includes(originalPath)) {
          content = content.replace(new RegExp(originalPath, 'g'), fingerprintedPath);
          updated = true;
        }
      }
      
      if (updated) {
        fs.writeFileSync(htmlFile, content);
        updatedFiles++;
      }
    }
    
    if (updatedFiles > 0) {
      console.log(`🔄 Updated asset references in ${updatedFiles} HTML files`);
    }
  }

  async startWatcher() {
    console.log('👀 Starting asset watcher...');
    
    const chokidar = require('chokidar');
    const watcher = chokidar.watch('.', {
      ignored: ['_site/**', 'node_modules/**', 'vendor/**', '.git/**'],
      persistent: true
    });
    
    watcher.on('change', async (path) => {
      const ext = path.extname(path);
      const assetType = Object.keys(this.config.assetTypes).find(type => 
        this.config.assetTypes[type].extensions.includes(ext)
      );
      
      if (assetType) {
        console.log(`🔄 Asset changed: ${path}`);
        try {
          await this.processFile(path, assetType, 'development');
          console.log(`✅ Reprocessed: ${path}`);
        } catch (error) {
          console.error(`❌ Error reprocessing ${path}:`, error.message);
        }
      }
    });
  }

  outputStats() {
    const sizeDifference = this.stats.sizeBefore - this.stats.sizeAfter;
    const percentageSaved = ((sizeDifference / this.stats.sizeBefore) * 100).toFixed(2);
    
    console.log('\n📊 Asset Optimization Statistics:');
    console.log(`   Files processed: ${this.stats.processed}`);
    console.log(`   Files optimized: ${this.stats.optimized}`);
    console.log(`   Errors: ${this.stats.errors}`);
    console.log(`   Size before: ${this.formatBytes(this.stats.sizeBefore)}`);
    console.log(`   Size after: ${this.formatBytes(this.stats.sizeAfter)}`);
    console.log(`   Saved: ${this.formatBytes(sizeDifference)} (${percentageSaved}%)`);
    console.log('');
  }

  formatBytes(bytes) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }
}

// CLI Interface
if (require.main === module) {
  const args = process.argv.slice(2);
  const options = {};
  
  for (let i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--mode':
        options.mode = args[++i];
        break;
      case '--watch':
        options.watch = true;
        break;
      case '--verbose':
        options.verbose = true;
        break;
      case '--types':
        options.types = args[++i].split(',');
        break;
    }
  }
  
  const optimizer = new AssetOptimizer();
  optimizer.optimize(options);
}

module.exports = AssetOptimizer;