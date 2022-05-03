it('works', () => {
  cy.visit('/jekyll-action/')
  cy.get('#jekyll_bundler_lock').should('be.visible')
  cy.get('body main div header h1').should('contain', 'Jekyll AsciiDoc Action - Jekyll Bundler Lock')
  cy.get('#env').should('contain', 'production')
  cy.get('#bundlerVersion').should('contain', '2.1.4')
})
