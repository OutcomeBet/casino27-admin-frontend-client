gulp = require 'gulp'
coffee      = require 'gulp-coffee'
pug         = require 'gulp-pug'
sass        = require 'gulp-sass'

files =
  coffee: [
    'src/api.coffee'
  ]
  demo_coffee: [
    'src/demo/js/main.coffee'
  ]
  demo_sass: [
    'src/demo/css/main.sass'
  ]
  demo_pug: [
    'src/demo/demo.pug'
  ]


gulp.task 'js', ->
  gulp.src files.coffee
  #.pipe concat 'main.coffee'
  .pipe coffee bare: true
  .pipe gulp.dest 'dist'

gulp.task 'demo_html', ->
  gulp.src files.demo_pug
    .pipe pug pretty: true
    .pipe gulp.dest 'dist/demo'
    .pipe gulp.dest '.'

gulp.task 'demo_css', ->
  gulp.src files.demo_sass
    .pipe sass()
    .pipe gulp.dest 'dist/demo/css'

gulp.task 'demo_js', ->
  gulp.src files.demo_coffee
    .pipe coffee bare: true
    .pipe gulp.dest 'dist/demo/js'



gulp.task 'watch_js', ['js'], ->
  gulp.watch files.coffee, ['js']

gulp.task 'watch_demo_html', ['demo_html'], ->
  gulp.watch files.demo_pug, ['demo_html']

gulp.task 'watch_demo_css', ['demo_css'], ->
  gulp.watch files.demo_sass, ['demo_css']

gulp.task 'watch_demo_js', ['demo_js'], ->
  gulp.watch files.demo_coffee, ['demo_js']


# common tasks
gulp.task 'default', ['js', 'demo']
gulp.task 'watch', ['watch_js', 'watch_demo']
gulp.task 'demo', ['demo_html', 'demo_css', 'demo_js']
gulp.task 'watch_demo', ['watch_demo_html', 'watch_demo_css', 'watch_demo_js']
