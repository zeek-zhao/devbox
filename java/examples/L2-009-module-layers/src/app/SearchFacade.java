package app;

public final class SearchFacade {
    private SearchFacade() {}

    public static SearchService create() {
        return new SearchServiceImpl();
    }
}
