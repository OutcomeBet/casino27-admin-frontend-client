gulp = require 'gulp'
coffee      = require 'gulp-coffee'

files =
  coffee: [
    'src/api.coffee'
  ]

gulp.task 'js', ->
  gulp.src files.coffee
  #.pipe concat 'main.coffee'
  .pipe coffee bare: true
  .pipe gulp.dest 'dist'

gulp.task 'watch_js', ['js'], ->
  gulp.watch files.coffee, ['js']


# common tasks
gulp.task 'default', ['js']
gulp.task 'watch', ['watch_js']
