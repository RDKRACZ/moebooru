#!/usr/bin/env node

import babel from '@babel/core'
import coffeeScriptPlugin from 'esbuild-coffeescript'
import esbuild from 'esbuild'
import fs from 'fs'

const outfileEsbuild = 'app/assets/builds/application_es6.js'
const outfileBabel = 'app/assets/builds/application.js'

const babelOnEnd = {
  name: 'babelOnEnd',
  setup (build) {
    build.onEnd(() => {
      const result = babel.transformSync(fs.readFileSync(outfileEsbuild), {
        presets: [
          ['@babel/preset-env']
        ]
      })
      fs.writeFileSync(outfileBabel, result.code)
    })
  }
}

esbuild.build({
  bundle: true,
  entryPoints: ['app/javascript/application.coffee'],
  nodePaths: ['app/javascript'],
  outfile: outfileEsbuild,
  plugins: [coffeeScriptPlugin({ bare: true }), babelOnEnd],
  resolveExtensions: ['.coffee', '.js'],
  sourcemap: true,
  watch: process.argv[2] === '--watch'
})
