it('works', () => {
  cy.visit('/jekyll-action/')
  cy.get('#build_dir').should('be.visible')
  cy.get('body main div header h1').should('contain', 'Jekyll AsciiDoc Action - Build dir')
})
