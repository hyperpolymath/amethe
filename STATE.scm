;; SPDX-License-Identifier: PMPL-1.0-or-later
;; STATE.scm - Project state for amethe

(state
  (metadata
    (version "0.0.1")
    (schema-version "1.0")
    (created "2024-06-01")
    (updated "2025-01-16")
    (project "amethe")
    (repo "hyperpolymath/amethe"))

  (project-context
    (name "Amethe")
    (tagline "Project specification pending")
    (tech-stack ("pending")))

  (current-position
    (phase "initialization")
    (overall-completion 5)
    (components
      ((infrastructure . 100)
       (specification . 0)
       (implementation . 0)))
    (working-features
      ("RSR-compliant scaffold"
       "CI/CD infrastructure"
       "Documentation templates")))

  (route-to-mvp
    (milestones
      ((name "Specification")
       (status "pending")
       (items
         ("Define project purpose"
          "Choose tech stack"
          "Architecture design")))
      ((name "Foundation")
       (status "pending")
       (items
         ("Core implementation"
          "Tests"
          "Documentation")))
      ((name "MVP")
       (status "pending")
       (items
         ("Working prototype"
          "User documentation"
          "Release")))))

  (blockers-and-issues
    (critical
      (("Specification" . "Project specification not yet uploaded")))
    (high ())
    (medium ())
    (low ()))

  (critical-next-actions
    (immediate
      ("Upload project specification"))
    (this-week
      ("Define architecture"))
    (this-month
      ("Begin implementation"))))
