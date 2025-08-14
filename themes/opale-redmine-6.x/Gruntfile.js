const livereloadPort = parseInt(process.env.LIVERELOAD_PORT || "35731", 10);

module.exports = function (grunt) {
  grunt.initConfig({
    src: "src/",

    sass: {
      options: {
        implementation: require("sass"),
        sourceMap: false,
        style: "compressed",
      },

      theme: {
        files: {
          "stylesheets/application.css": "<%= src %>sass/application.scss",
        },
      },
    },

    copy: {
      js: {
        files: [
          {
            expand: true,
            cwd: "<%= src %>js",
            src: ["**/*.js"],
            dest: "javascripts/",
          },
        ],
      },
    },

    // BrowserSync는 제거(포트 3000에서 rack-livereload 사용)

    postcss: {
      options: {
        processors: [require("autoprefixer")()],
      },

      all: {
        src: ["stylesheets/*.css", "plugins/**/*.css"],
      },
    },

    watch: {
      options: {
        interval: 500,
        debounceDelay: 300,
        spawn: true,
      },
      css: {
        files: ["<%= src %>sass/**/*.scss"],
        tasks: ["css"],
      },
      css_out: {
        files: ["stylesheets/*.css"],
        options: { livereload: livereloadPort },
      },
      js: {
        files: ["<%= src %>js/**/*.js"],
        tasks: ["copy:js"],
      },
    },
  });

  grunt.loadNpmTasks("grunt-sass");
  grunt.loadNpmTasks("@lodder/grunt-postcss");
  grunt.loadNpmTasks("grunt-contrib-watch");
  grunt.loadNpmTasks("grunt-contrib-copy");

  grunt.registerTask("css", ["sass", "postcss"]);

  grunt.registerTask("default", ["css", "copy:js"]);
};
