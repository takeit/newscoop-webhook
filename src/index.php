<?php

require_once __DIR__.'/../vendor/autoload.php';

use Symfony\Component\HttpFoundation\Request;

$app = new Silex\Application();

$app->before(function (Request $request) {
    if (0 === strpos($request->headers->get('Content-Type'), 'application/json')) {
        $data = json_decode($request->getContent(), true);
        $request->request->replace(is_array($data) ? $data : array());
    }
});

$app->get('/', function () use ($app) {
    return 'Access Denied!';
});

$app->post('/payload', function (Request $request) use ($app) {

    if ($request->get('hook_id')) {
        return $app->json(true, 200);
    }

    switch ($request->get('action')) {
        case 'published':
            $repository = $request->get('repository');
            $release = $request->get('release');
            $branch = $repository['default_branch'];
            $tag = $release['tag_name'];
            exec('./package.sh -i -b '.$branch.' -f tar -o prod -p newscoop-prod-'.$tag);

            break;

        case 'opened':
            $repository = $request->get('repository');
            $branch = $repository['default_branch'];
            $pullRequestNumber = $request->get('number');

            exec('./package.sh -i -b '.$branch.' -f tar -o test -p newscoop-test-'.$pullRequestNumber);

            break;

        case 'closed':
            $pullRequest = $request->get('pull_request');
            if ($pullRequest['base']['merged']) {
                $repository = $request->get('repository');
                $branch = $repository['default_branch'];
                $pullRequestNumber = $request->get('number');

                exec('./package.sh -i -b '.$branch.' -f tar -o dev -p newscoop-dev-'.$pullRequestNumber);
            }

            break;

        default:
            return $app->json(false, 500);

            break;
    }

    return $app->json(true, 201);
});

$app->get('/packages', function (Request $request) use ($app) {

});

$app->run();
